import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { deriveLabel } from "@/lib/labels";
import { VOUCH_THRESHOLD } from "@/lib/config";
import VouchButton from "@/components/VouchButton";

// Verified members vouch for pending Penguins seeking confirmation (§3.3).
export default async function VouchPage() {
  const me = await requireVerified();

  const seekers = await prisma.member.findMany({
    where: {
      verificationStatus: "pending",
      verificationRequests: { some: { method: "vouch", status: "pending" } },
    },
    include: {
      attendanceSpans: { take: 1 },
      vouchesReceived: {
        where: { voucher: { verificationStatus: "verified" } },
        select: { voucherId: true },
      },
    },
    orderBy: { createdAt: "asc" },
  });

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Vouch for Penguins</h1>
        <p className="mt-1 text-sm text-deep-700/70">
          Only vouch for people you genuinely remember. {VOUCH_THRESHOLD} vouches
          confirm a member.
        </p>
      </div>

      {seekers.length === 0 && (
        <p className="card text-sm text-deep-700/70">
          No one is waiting for vouches right now.
        </p>
      )}

      <div className="space-y-3">
        {seekers.map((s) => {
          const alreadyVouched = s.vouchesReceived.some(
            (v) => v.voucherId === me.id,
          );
          return (
            <div key={s.id} className="card flex items-center justify-between">
              <div>
                <p className="font-medium">{s.displayName}</p>
                <p className="chip mt-1">
                  {deriveLabel(s.role, s.attendanceSpans[0])}
                </p>
                {s.homeCity && (
                  <p className="mt-1 text-xs text-deep-700/60">
                    {s.homeCity}, {s.homeCountry}
                  </p>
                )}
                <p className="mt-1 text-xs text-deep-700/60">
                  {s.vouchesReceived.length}/{VOUCH_THRESHOLD} vouches
                </p>
              </div>
              <VouchButton voucheeId={s.id} alreadyVouched={alreadyVouched} />
            </div>
          );
        })}
      </div>
    </div>
  );
}
