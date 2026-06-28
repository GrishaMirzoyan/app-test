import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireMember } from "@/lib/gate";

const CreateBody = z.object({
  kind: z.enum(["work", "education"]),
  org: z.string().min(1),
  title: z.string().min(1),
  startYear: z.number().int().optional().nullable(),
  endYear: z.number().int().optional().nullable(),
  visibility: z.enum(["friends", "verified_members", "hidden"]),
});

// Work & education entries (§3.4), each with its own visibility (§1).
export async function POST(req: Request) {
  const me = await requireMember();
  const parsed = CreateBody.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const entry = await prisma.profileEntry.create({
    data: { memberId: me.id, ...parsed.data },
  });
  return NextResponse.json({ ok: true, id: entry.id });
}

const DeleteBody = z.object({ id: z.string().uuid() });

export async function DELETE(req: Request) {
  const me = await requireMember();
  const parsed = DeleteBody.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  // Only the owner can delete their entry.
  await prisma.profileEntry.deleteMany({
    where: { id: parsed.data.id, memberId: me.id },
  });
  return NextResponse.json({ ok: true });
}
