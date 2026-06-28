import { requireAdmin } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { deriveLabel } from "@/lib/labels";
import AdminReviewButtons from "@/components/AdminReviewButtons";

// Admin review of era-corroboration requests (§3.3b) — the thin-network path.
export default async function AdminPage() {
  await requireAdmin();

  const requests = await prisma.verificationRequest.findMany({
    where: { method: "era_corroboration", status: "pending" },
    include: { member: { include: { attendanceSpans: { take: 1 } } } },
    orderBy: { createdAt: "asc" },
  });

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Era-corroboration review</h1>
      <p className="text-sm text-deep-700/70">
        Approve only when the details are consistent with a real Penguin of that
        era. Yearbooks in the Library are a corroboration reference.
      </p>

      {requests.length === 0 && (
        <p className="card text-sm text-deep-700/70">Nothing awaiting review.</p>
      )}

      <div className="space-y-3">
        {requests.map((r) => (
          <div key={r.id} className="card">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">
                  {r.member.displayName}{" "}
                  <span className="text-xs text-deep-700/50">
                    (legal: {r.member.legalName})
                  </span>
                </p>
                <p className="chip mt-1">
                  {deriveLabel(r.member.role, r.member.attendanceSpans[0])}
                </p>
              </div>
              <AdminReviewButtons requestId={r.id} />
            </div>
            <p className="mt-3 whitespace-pre-wrap rounded-lg bg-ice-50 p-3 text-sm">
              {r.corroborationDetails}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
