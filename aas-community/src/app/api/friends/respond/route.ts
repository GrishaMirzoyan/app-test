import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";

const Body = z.object({
  requesterId: z.string().uuid(),
  accept: z.boolean(),
});

// Respond to an incoming friend request (I am the addressee).
export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const { requesterId, accept } = parsed.data;

  const fr = await prisma.friendship.findUnique({
    where: { requesterId_addresseeId: { requesterId, addresseeId: me.id } },
  });
  if (!fr || fr.status !== "pending") {
    return NextResponse.json({ error: "No pending request." }, { status: 404 });
  }

  if (accept) {
    await prisma.friendship.update({ where: { id: fr.id }, data: { status: "accepted" } });
  } else {
    await prisma.friendship.delete({ where: { id: fr.id } });
  }
  return NextResponse.json({ ok: true });
}
