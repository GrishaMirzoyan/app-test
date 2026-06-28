import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";

const Body = z.object({ addresseeId: z.string().uuid() });

export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const { addresseeId } = parsed.data;
  if (addresseeId === me.id) {
    return NextResponse.json({ error: "Cannot friend yourself." }, { status: 400 });
  }

  // If the other side already requested me, accept it instead of duplicating.
  const reverse = await prisma.friendship.findUnique({
    where: { requesterId_addresseeId: { requesterId: addresseeId, addresseeId: me.id } },
  });
  if (reverse) {
    if (reverse.status === "pending") {
      await prisma.friendship.update({
        where: { id: reverse.id },
        data: { status: "accepted" },
      });
    }
    return NextResponse.json({ ok: true, status: "accepted" });
  }

  await prisma.friendship.upsert({
    where: { requesterId_addresseeId: { requesterId: me.id, addresseeId } },
    create: { requesterId: me.id, addresseeId, status: "pending" },
    update: {},
  });
  return NextResponse.json({ ok: true, status: "pending" });
}
