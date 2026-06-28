import { redirect } from "next/navigation";
import { requireMember } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { countValidVouches } from "@/lib/verification";
import { VOUCH_THRESHOLD } from "@/lib/config";
import { deriveLabel } from "@/lib/labels";
import VerifyForm from "@/components/VerifyForm";
import SignOutButton from "@/components/SignOutButton";

// The verification screen — the only thing an unverified member sees beyond
// onboarding (§1, §4.2).
export default async function VerifyPage() {
  const me = await requireMember();
  const record = await prisma.member.findUnique({
    where: { id: me.id },
    include: { attendanceSpans: { take: 1 }, verificationRequests: { orderBy: { createdAt: "desc" }, take: 1 } },
  });
  if (!record) redirect("/");
  if (!record.homeCity || record.attendanceSpans.length === 0) redirect("/onboarding");
  if (record.verificationStatus === "verified") redirect("/dashboard");

  const span = record.attendanceSpans[0];
  const label = deriveLabel(record.role, span);
  const openRequest = record.verificationRequests[0] ?? null;
  const vouches = await countValidVouches(me.id);

  return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Confirmed as a Penguin</h1>
          <p className="mt-1 text-sm text-deep-700/70">
            There&apos;s no registrar to check against. Membership is established
            by peers who remember you, or by an admin reviewing the details only
            a real Penguin would know.
          </p>
        </div>
        <SignOutButton />
      </div>

      <div className="card mt-6">
        <p className="text-sm text-deep-700/70">You&apos;ll appear to others as</p>
        <p className="mt-1 text-lg font-medium">{record.displayName}</p>
        <p className="chip mt-2">{label}</p>
        {record.verificationStatus === "rejected" && (
          <p className="mt-3 rounded-lg bg-red-50 p-3 text-sm text-red-700">
            A previous request was not approved. You can submit a new one below.
          </p>
        )}
      </div>

      <div className="mt-6">
        <VerifyForm
          memberId={me.id}
          vouches={vouches}
          threshold={VOUCH_THRESHOLD}
          openRequest={
            openRequest
              ? { method: openRequest.method, status: openRequest.status }
              : null
          }
        />
      </div>

      <p className="mt-6 text-center text-xs text-deep-700/50">
        Until you&apos;re confirmed, you can only see this screen. No directory,
        archive, map, or chat is visible yet.
      </p>
    </main>
  );
}
