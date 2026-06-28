import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireMember } from "@/lib/gate";
import { cityCentroid } from "@/lib/cities";

const Body = z.object({
  displayName: z.string().min(1),
  isPseudonymous: z.boolean(),
  allowFaceTagging: z.boolean(),
  mapVisibility: z.enum(["city", "country", "hidden"]),
  homeCity: z.string().min(1),
  homeCountry: z.string().min(1),
});

// Update identity + privacy controls. Tagging opt-out is honored retroactively
// and prospectively (§1) — the tag-creation endpoint reads allowFaceTagging live,
// and existing tags are filtered out on read when the flag is off.
export async function POST(req: Request) {
  const me = await requireMember();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const d = parsed.data;
  const centroid = cityCentroid(d.homeCity, d.homeCountry);

  await prisma.member.update({
    where: { id: me.id },
    data: {
      displayName: d.displayName,
      isPseudonymous: d.isPseudonymous,
      allowFaceTagging: d.allowFaceTagging,
      mapVisibility: d.mapVisibility,
      homeCity: d.homeCity,
      homeCountry: d.homeCountry,
      homeLat: centroid?.lat ?? null,
      homeLng: centroid?.lng ?? null,
      cityUpdatedAt: new Date(),
    },
  });
  return NextResponse.json({ ok: true });
}
