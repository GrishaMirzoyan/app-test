import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";
import { areFriends } from "@/lib/friends";
import { findOrCreateDmThread } from "@/lib/chat";

const Body = z.object({ memberId: z.string().uuid() });

// Open a DM. Message requests gate first contact from non-friends (§1): a DM is
// only delivered if the two are friends OR a message_request has been accepted.
export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const other = parsed.data.memberId;
  if (other === me.id) {
    return NextResponse.json({ error: "That's you." }, { status: 400 });
  }

  const friends = await areFriends(me.id, other);

  // An accepted request (either direction) also unlocks the DM.
  const acceptedReq = await prisma.messageRequest.findFirst({
    where: {
      status: "accepted",
      OR: [
        { fromId: me.id, toId: other },
        { fromId: other, toId: me.id },
      ],
    },
  });

  if (friends || acceptedReq) {
    const threadId = await findOrCreateDmThread(me.id, other);
    return NextResponse.json({ threadId });
  }

  // Otherwise raise a message request — no unsolicited DM reaches the inbox.
  await prisma.messageRequest.upsert({
    where: { fromId_toId: { fromId: me.id, toId: other } },
    create: { fromId: me.id, toId: other, status: "pending" },
    update: {},
  });
  return NextResponse.json({ requested: true });
}
