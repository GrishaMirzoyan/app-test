import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireMember } from "@/lib/gate";
import { cityCentroid } from "@/lib/cities";

const Body = z.object({
  role: z.enum(["student", "faculty", "staff"]),
  displayName: z.string().min(1),
  isPseudonymous: z.boolean().default(false),
  homeCity: z.string().min(1),
  homeCountry: z.string().min(1),
  mapVisibility: z.enum(["city", "country", "hidden"]).default("city"),
  span: z.object({
    startYear: z.number().int().min(1940).max(2030),
    endYear: z.number().int().min(1940).max(2030),
    entryGrade: z.string().optional().nullable(),
    exitGrade: z.string().optional().nullable(),
    graduated: z.boolean().default(false),
    divisions: z.array(z.enum(["elementary", "middle", "high"])).default([]),
    subjects: z.array(z.string()).default([]),
    gradesTaught: z.array(z.string()).default([]),
    staffRole: z.string().optional().nullable(),
  }),
});

// Onboarding (§4.2): collects role + attendance span + home city. Replaces any
// prior span (re-run onboarding to edit). Stores ONLY a city centroid for the
// map — never precise coordinates (§1).
export async function POST(req: Request) {
  const me = await requireMember();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? "Invalid input" },
      { status: 400 },
    );
  }
  const d = parsed.data;
  if (d.span.endYear < d.span.startYear) {
    return NextResponse.json(
      { error: "End year cannot be before start year." },
      { status: 400 },
    );
  }

  const centroid = cityCentroid(d.homeCity, d.homeCountry);

  await prisma.$transaction([
    prisma.member.update({
      where: { id: me.id },
      data: {
        role: d.role,
        displayName: d.displayName,
        isPseudonymous: d.isPseudonymous,
        homeCity: d.homeCity,
        homeCountry: d.homeCountry,
        homeLat: centroid?.lat ?? null,
        homeLng: centroid?.lng ?? null,
        cityUpdatedAt: new Date(),
        mapVisibility: d.mapVisibility,
      },
    }),
    prisma.attendanceSpan.deleteMany({ where: { memberId: me.id } }),
    prisma.attendanceSpan.create({
      data: {
        memberId: me.id,
        startYear: d.span.startYear,
        endYear: d.span.endYear,
        entryGrade: d.role === "student" ? d.span.entryGrade ?? null : null,
        exitGrade: d.role === "student" ? d.span.exitGrade ?? null : null,
        graduated: d.role === "student" ? d.span.graduated : false,
        divisions: d.span.divisions,
        subjects: d.role === "faculty" ? d.span.subjects : [],
        gradesTaught: d.role === "faculty" ? d.span.gradesTaught : [],
        staffRole: d.role === "staff" ? d.span.staffRole ?? null : null,
      },
    }),
  ]);

  return NextResponse.json({ ok: true });
}
