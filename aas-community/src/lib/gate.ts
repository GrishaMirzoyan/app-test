// The verification gate (§1, §4.8). Unverified accounts can complete onboarding
// and a verification request — and nothing else. No directory, archive, chat, or
// map until verified. These guards are the single chokepoint every sensitive
// server component and route handler calls.

import { redirect } from "next/navigation";
import { auth } from "./auth";
import { prisma } from "./prisma";
import type { Member } from "@prisma/client";

export interface SessionMember {
  id: string;
  role: string;
  verificationStatus: string;
  isAdmin: boolean;
  email?: string | null;
}

// Returns the session member or null. No side effects.
export async function currentMember(): Promise<SessionMember | null> {
  const session = await auth();
  if (!session?.member?.id) return null;
  return {
    id: session.member.id,
    role: session.member.role,
    verificationStatus: session.member.verificationStatus,
    isAdmin: session.member.isAdmin,
    email: session.member.email,
  };
}

// Requires a signed-in member (verified or not). Redirects to the threshold if not.
export async function requireMember(): Promise<SessionMember> {
  const m = await currentMember();
  if (!m) redirect("/");
  return m;
}

// Requires a VERIFIED member. Unverified → bounced to the verification screen.
// This is the gate: every sensitive page calls it.
export async function requireVerified(): Promise<SessionMember> {
  const m = await requireMember();
  if (m.verificationStatus !== "verified") redirect("/verify");
  return m;
}

export async function requireAdmin(): Promise<SessionMember> {
  const m = await requireVerified();
  if (!m.isAdmin) redirect("/dashboard");
  return m;
}

// Full member record for the current session (or null).
export async function currentMemberRecord(): Promise<Member | null> {
  const m = await currentMember();
  if (!m) return null;
  return prisma.member.findUnique({ where: { id: m.id } });
}
