import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";
import { findOrCreateDmThread } from "@/lib/chat";

const Body = z.object({
  requestId: z.string().uuid(),
  accept: z.boolean(),
});

// Respond to an incoming message request (I am the recipient). Accepting opens
// the DM thread; declining drops it. No unsolicited DM ever reaches the inbox (§1).
export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  const mr = await prisma.messageRequest.findUnique({
    where: { id: parsed.data.requestId },
  });
  if (!mr || mr.toId !== me.id || mr.status !== "pending") {
    return NextResponse.json({ error: "No pending request." }, { status: 404 });
  }

  if (!parsed.data.accept) {
    await prisma.messageRequest.update({
      where: { id: mr.id },
      data: { status: "declined" },
    });
    return NextResponse.json({ ok: true });
  }

  await prisma.messageRequest.update({
    where: { id: mr.id },
    data: { status: "accepted" },
  });
  const threadId = await findOrCreateDmThread(mr.fromId, mr.toId);
  return NextResponse.json({ ok: true, threadId });
}
