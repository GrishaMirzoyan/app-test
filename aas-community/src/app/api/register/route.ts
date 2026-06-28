import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { hashPassword } from "@/lib/auth";

const Body = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters."),
  legalName: z.string().min(1),
});

// Registration creates a PENDING member with email/password. Onboarding (role,
// attendance span, home city) and verification happen after first sign-in.
export async function POST(req: Request) {
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? "Invalid input" },
      { status: 400 },
    );
  }
  const email = parsed.data.email.toLowerCase().trim();

  const existing = await prisma.member.findUnique({ where: { email } });
  if (existing) {
    return NextResponse.json(
      { error: "An account with that email already exists." },
      { status: 409 },
    );
  }

  const passwordHash = await hashPassword(parsed.data.password);
  await prisma.member.create({
    data: {
      email,
      passwordHash,
      legalName: parsed.data.legalName,
      // Default display name is the legal name; the member can switch to a
      // pseudonym during onboarding (§1 pseudonymity).
      displayName: parsed.data.legalName,
      role: "student",
      verificationStatus: "pending",
    },
  });

  return NextResponse.json({ ok: true });
}
