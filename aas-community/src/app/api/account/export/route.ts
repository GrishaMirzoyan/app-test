import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireMember } from "@/lib/gate";

// Data export (§1): a member can export their own data.
export async function GET() {
  const me = await requireMember();

  const member = await prisma.member.findUnique({
    where: { id: me.id },
    include: {
      attendanceSpans: true,
      profileEntries: true,
      uploadedArchiveItems: true,
      sentMessages: true,
      vouchesGiven: true,
      vouchesReceived: true,
    },
  });
  if (!member) return NextResponse.json({ error: "Not found" }, { status: 404 });

  // Strip the password hash from the export.
  const { passwordHash: _omit, ...safe } = member;

  return new NextResponse(JSON.stringify(safe, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Content-Disposition": `attachment; filename="aas-community-export.json"`,
    },
  });
}
