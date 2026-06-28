import { NextResponse } from "next/server";
import { z } from "zod";
import { requireAdmin } from "@/lib/gate";
import { adminApprove, adminReject } from "@/lib/verification";

const Body = z.object({
  requestId: z.string().uuid(),
  decision: z.enum(["approve", "reject"]),
});

export async function POST(req: Request) {
  const me = await requireAdmin();
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  if (parsed.data.decision === "approve") {
    await adminApprove(parsed.data.requestId, me.id);
  } else {
    await adminReject(parsed.data.requestId, me.id);
  }
  return NextResponse.json({ ok: true });
}
