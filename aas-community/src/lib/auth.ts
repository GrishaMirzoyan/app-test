// Conventional, well-supported auth only (§1): Auth.js (NextAuth) with
// email/password (bcrypt) plus optional Google/Apple OAuth. No custom crypto.
//
// Sessions use the JWT strategy; the JWT carries the member id, role, and
// verification status so the gate can run without a DB hit on every request.

import NextAuth, { type DefaultSession } from "next-auth";
import Credentials from "next-auth/providers/credentials";
import Google from "next-auth/providers/google";
import Apple from "next-auth/providers/apple";
import bcrypt from "bcryptjs";
import { prisma } from "./prisma";

declare module "next-auth" {
  interface Session {
    member: {
      id: string;
      role: string;
      verificationStatus: string;
      isAdmin: boolean;
    } & DefaultSession["user"];
  }
}

const providers = [
  Credentials({
    name: "Email",
    credentials: {
      email: { label: "Email", type: "email" },
      password: { label: "Password", type: "password" },
    },
    async authorize(creds) {
      const email = String(creds?.email ?? "").toLowerCase().trim();
      const password = String(creds?.password ?? "");
      if (!email || !password) return null;

      const member = await prisma.member.findUnique({ where: { email } });
      if (!member?.passwordHash) return null;

      const ok = await bcrypt.compare(password, member.passwordHash);
      if (!ok) return null;

      return { id: member.id, email: member.email, name: member.displayName };
    },
  }),
];

if (process.env.AUTH_GOOGLE_ID && process.env.AUTH_GOOGLE_SECRET) {
  providers.push(
    Google({
      clientId: process.env.AUTH_GOOGLE_ID,
      clientSecret: process.env.AUTH_GOOGLE_SECRET,
    }) as never,
  );
}

if (process.env.AUTH_APPLE_ID && process.env.AUTH_APPLE_SECRET) {
  providers.push(
    Apple({
      clientId: process.env.AUTH_APPLE_ID,
      clientSecret: process.env.AUTH_APPLE_SECRET,
    }) as never,
  );
}

export const { handlers, auth, signIn, signOut } = NextAuth({
  trustHost: true,
  session: { strategy: "jwt" },
  pages: { signIn: "/" },
  providers,
  callbacks: {
    // For OAuth sign-ins, find-or-create the Member by email and link an Account.
    async signIn({ user, account }) {
      if (!account || account.provider === "credentials") return true;
      const email = user.email?.toLowerCase().trim();
      if (!email) return false;

      let member = await prisma.member.findUnique({ where: { email } });
      if (!member) {
        // New OAuth member: created pending; onboarding collects role/span/city.
        member = await prisma.member.create({
          data: {
            email,
            legalName: user.name ?? email,
            displayName: user.name ?? email.split("@")[0],
            role: "student",
            authProviderId: account.providerAccountId,
          },
        });
      }
      await prisma.account.upsert({
        where: {
          provider_providerAccountId: {
            provider: account.provider,
            providerAccountId: account.providerAccountId,
          },
        },
        create: {
          memberId: member.id,
          provider: account.provider,
          providerAccountId: account.providerAccountId,
          type: account.type,
        },
        update: {},
      });
      return true;
    },

    async jwt({ token, user }) {
      // On first sign-in `user` is present; afterwards re-hydrate from email.
      const email = (user?.email ?? token.email)?.toString().toLowerCase();
      if (email) {
        const member = await prisma.member.findUnique({
          where: { email },
          select: { id: true, role: true, verificationStatus: true, isAdmin: true },
        });
        if (member) {
          token.memberId = member.id;
          token.role = member.role;
          token.verificationStatus = member.verificationStatus;
          token.isAdmin = member.isAdmin;
        }
      }
      return token;
    },

    async session({ session, token }) {
      session.member = {
        id: String(token.memberId ?? ""),
        role: String(token.role ?? "student"),
        verificationStatus: String(token.verificationStatus ?? "pending"),
        isAdmin: Boolean(token.isAdmin),
        name: session.user?.name,
        email: session.user?.email,
        image: session.user?.image,
      };
      return session;
    },
  },
});

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}
