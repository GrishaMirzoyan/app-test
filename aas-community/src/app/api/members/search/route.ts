import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";
import { deriveLabel } from "@/lib/labels";

// Lightweight verified-member typeahead, used by archive tagging and chat.
export async function GET(req: Request) {
  await requireVerified();
  const q = new URL(req.url).searchParams.get("q")?.trim() ?? "";
  if (q.length < 2) return NextResponse.json({ members: [] });

  const members = await prisma.member.findMany({
    where: {
      verificationStatus: "verified",
      displayName: { contains: q, mode: "insensitive" },
    },
    include: { attendanceSpans: { take: 1, orderBy: { startYear: "asc" } } },
    take: 10,
    orderBy: { displayName: "asc" },
  });

  return NextResponse.json({
    members: members.map((m) => ({
      id: m.id,
      name: m.displayName,
      label: deriveLabel(m.role, m.attendanceSpans[0]),
    })),
  });
}
