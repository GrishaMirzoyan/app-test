import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";

const Body = z.object({ year: z.number().int().min(1940).max(2030) });

// Cohort-seeded group chat (§4.7) — the feature that keeps chat from launching
// empty: "start a chat with everyone who overlapped with me in {year}", seeded
// straight from the directory (era-overlap on a single year).
export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Pick a year." }, { status: 400 });
  }
  const { year } = parsed.data;

  const members = await prisma.member.findMany({
    where: {
      verificationStatus: "verified",
      attendanceSpans: { some: { startYear: { lte: year }, endYear: { gte: year } } },
    },
    select: { id: true },
    take: 500,
  });

  const ids = new Set(members.map((m) => m.id));
  ids.add(me.id);
  if (ids.size < 2) {
    return NextResponse.json(
      { error: "No other Penguins were here that year yet." },
      { status: 400 },
    );
  }

  const thread = await prisma.chatThread.create({
    data: {
      type: "group",
      name: `Penguins of ${year}`,
      createdBy: me.id,
      memberships: { create: [...ids].map((memberId) => ({ memberId })) },
    },
  });
  return NextResponse.json({ threadId: thread.id, count: ids.size });
}
