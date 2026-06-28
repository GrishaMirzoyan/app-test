import { NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";
import { reevaluateVouchVerification } from "@/lib/verification";

const Body = z.object({ voucheeId: z.string().uuid() });

// Only a VERIFIED member may vouch (§3.3). Crossing the threshold auto-verifies
// the vouchee.
export async function POST(req: Request) {
  const me = await requireVerified();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const { voucheeId } = parsed.data;
  if (voucheeId === me.id) {
    return NextResponse.json({ error: "You cannot vouch for yourself." }, { status: 400 });
  }

  const vouchee = await prisma.member.findUnique({
    where: { id: voucheeId },
    select: { verificationStatus: true },
  });
  if (!vouchee || vouchee.verificationStatus === "verified") {
    return NextResponse.json({ error: "Not a pending member." }, { status: 400 });
  }

  await prisma.vouch.upsert({
    where: { voucherId_voucheeId: { voucherId: me.id, voucheeId } },
    create: { voucherId: me.id, voucheeId },
    update: {},
  });

  const verified = await reevaluateVouchVerification(voucheeId);
  return NextResponse.json({ ok: true, verified });
}
