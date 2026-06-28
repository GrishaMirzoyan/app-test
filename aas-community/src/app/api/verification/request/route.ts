import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireMember } from "@/lib/gate";

const Body = z.object({
  method: z.enum(["vouch", "era_corroboration"]),
  corroborationDetails: z.string().optional(),
});

// A pending member opens a verification request (§4.2). Vouch-method requests
// wait for peers to vouch; era_corroboration requests go to admin review.
export async function POST(req: Request) {
  const me = await requireMember();
  if (me.verificationStatus === "verified") {
    return NextResponse.json({ error: "Already verified." }, { status: 400 });
  }
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  if (
    parsed.data.method === "era_corroboration" &&
    !parsed.data.corroborationDetails?.trim()
  ) {
    return NextResponse.json(
      { error: "Corroboration details are required for admin review." },
      { status: 400 },
    );
  }

  // One open request at a time — replace any prior pending one.
  await prisma.verificationRequest.deleteMany({
    where: { memberId: me.id, status: "pending" },
  });
  await prisma.verificationRequest.create({
    data: {
      memberId: me.id,
      method: parsed.data.method,
      corroborationDetails: parsed.data.corroborationDetails?.trim() || null,
    },
  });

  return NextResponse.json({ ok: true });
}
