// Verification logic (§3.3). A request approves when EITHER:
//   (a) it reaches the vouch threshold from already-verified members, OR
//   (b) an admin approves an era-corroboration request (thin-network cases).
// Seed the first cohort manually — the founder is the trust root.

import { prisma } from "./prisma";
import { VOUCH_THRESHOLD } from "./config";

// Count valid vouches (from verified members) for a vouchee.
export async function countValidVouches(voucheeId: string): Promise<number> {
  return prisma.vouch.count({
    where: { voucheeId, voucher: { verificationStatus: "verified" } },
  });
}

// Promote a member to verified, closing any open request.
async function markVerified(memberId: string) {
  await prisma.$transaction([
    prisma.member.update({
      where: { id: memberId },
      data: { verificationStatus: "verified", verifiedAt: new Date() },
    }),
    prisma.verificationRequest.updateMany({
      where: { memberId, status: "pending" },
      data: { status: "approved" },
    }),
  ]);
}

// Re-evaluate a member's vouch-based verification. Returns true if this call
// crossed the threshold and verified them.
export async function reevaluateVouchVerification(
  voucheeId: string,
): Promise<boolean> {
  const member = await prisma.member.findUnique({
    where: { id: voucheeId },
    select: { verificationStatus: true },
  });
  if (!member || member.verificationStatus === "verified") return false;

  const count = await countValidVouches(voucheeId);
  if (count >= VOUCH_THRESHOLD) {
    await markVerified(voucheeId);
    return true;
  }
  return false;
}

// Admin approval path for era-corroboration requests (§3.3b).
export async function adminApprove(requestId: string, reviewerId: string) {
  const req = await prisma.verificationRequest.findUnique({
    where: { id: requestId },
  });
  if (!req || req.status !== "pending") return;
  await prisma.verificationRequest.update({
    where: { id: requestId },
    data: { status: "approved", reviewedBy: reviewerId },
  });
  await markVerified(req.memberId);
}

export async function adminReject(requestId: string, reviewerId: string) {
  await prisma.verificationRequest.update({
    where: { id: requestId },
    data: { status: "rejected", reviewedBy: reviewerId },
  });
}
