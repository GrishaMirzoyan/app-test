import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireMember } from "@/lib/gate";

// Account & data deletion (§1). Cascading FKs remove the member's attendance,
// profile entries, uploaded archive items, vouches, friendships, chat
// memberships, messages, and message requests. Archive tags pointing AT this
// member are set null (the photo survives; the personal link does not).
export async function POST() {
  const me = await requireMember();
  await prisma.member.delete({ where: { id: me.id } });
  return NextResponse.json({ ok: true });
}
