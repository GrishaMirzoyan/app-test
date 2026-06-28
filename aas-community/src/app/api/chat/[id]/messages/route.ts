import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";

async function assertMember(threadId: string, memberId: string) {
  const m = await prisma.chatMembership.findUnique({
    where: { threadId_memberId: { threadId, memberId } },
  });
  return !!m;
}

// Poll messages (real-time transport would replace this in production; the
// shape is identical). Only thread members can read.
export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const me = await requireVerified();
  const { id } = await params;
  if (!(await assertMember(id, me.id))) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const after = new URL(req.url).searchParams.get("after");
  const messages = await prisma.message.findMany({
    where: { threadId: id, ...(after ? { createdAt: { gt: new Date(after) } } : {}) },
    include: { sender: { select: { id: true, displayName: true } } },
    orderBy: { createdAt: "asc" },
    take: 200,
  });

  await prisma.chatMembership.update({
    where: { threadId_memberId: { threadId: id, memberId: me.id } },
    data: { lastReadAt: new Date() },
  });

  return NextResponse.json({
    messages: messages.map((m) => ({
      id: m.id,
      body: m.body,
      senderId: m.senderId,
      senderName: m.sender.displayName,
      createdAt: m.createdAt.toISOString(),
    })),
  });
}

const Body = z.object({ body: z.string().trim().min(1).max(4000) });

export async function POST(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const me = await requireVerified();
  const { id } = await params;
  if (!(await assertMember(id, me.id))) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Empty message." }, { status: 400 });
  }

  const msg = await prisma.message.create({
    data: { threadId: id, senderId: me.id, body: parsed.data.body },
  });
  return NextResponse.json({ ok: true, id: msg.id });
}
