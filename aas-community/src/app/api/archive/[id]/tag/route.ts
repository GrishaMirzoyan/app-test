import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";

const Body = z.object({
  // Either a member reference (a face) or a free-text label (room, or a name
  // that isn't a member). At least one must be present.
  taggedMemberId: z.string().uuid().optional(),
  label: z.string().trim().min(1).optional(),
});

// Crowdsourced tagging (§4.6). Honors allow_face_tagging (§1) before tagging a
// member — both retroactively and prospectively.
export async function POST(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const me = await requireVerified();
  const { id: archiveItemId } = await params;

  const item = await prisma.archiveItem.findUnique({ where: { id: archiveItemId } });
  if (!item) return NextResponse.json({ error: "Not found." }, { status: 404 });

  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success || (!parsed.data.taggedMemberId && !parsed.data.label)) {
    return NextResponse.json(
      { error: "Provide a member or a label." },
      { status: 400 },
    );
  }

  if (parsed.data.taggedMemberId) {
    const target = await prisma.member.findUnique({
      where: { id: parsed.data.taggedMemberId },
      select: { allowFaceTagging: true },
    });
    if (!target) {
      return NextResponse.json({ error: "Member not found." }, { status: 404 });
    }
    // Tagging opt-out is load-bearing (§1).
    if (!target.allowFaceTagging) {
      return NextResponse.json(
        { error: "This member does not allow being tagged." },
        { status: 403 },
      );
    }
  }

  const tag = await prisma.archiveTag.create({
    data: {
      archiveItemId,
      taggedMemberId: parsed.data.taggedMemberId ?? null,
      label: parsed.data.label ?? null,
      addedBy: me.id,
    },
  });
  return NextResponse.json({ ok: true, id: tag.id });
}
