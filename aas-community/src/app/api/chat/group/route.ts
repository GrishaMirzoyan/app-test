import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";

const Body = z.object({
  name: z.string().trim().min(1).max(80),
  memberIds: z.array(z.string().uuid()).min(1),
});

// Member-formed group chat (§4.7).
export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Name and members required." }, { status: 400 });
  }

  // Only seed with verified members.
  const verified = await prisma.member.findMany({
    where: { id: { in: parsed.data.memberIds }, verificationStatus: "verified" },
    select: { id: true },
  });
  const ids = new Set(verified.map((m) => m.id));
  ids.add(me.id);

  const thread = await prisma.chatThread.create({
    data: {
      type: "group",
      name: parsed.data.name,
      createdBy: me.id,
      memberships: { create: [...ids].map((memberId) => ({ memberId })) },
    },
  });
  return NextResponse.json({ threadId: thread.id });
}
