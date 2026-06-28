import Link from "next/link";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { deriveLabel } from "@/lib/labels";
import { PHASE2_MEMBER_THRESHOLD } from "@/lib/config";

export default async function Dashboard() {
  const me = await requireVerified();
  const [record, verifiedCount, pendingVouchSeekers] = await Promise.all([
    prisma.member.findUnique({
      where: { id: me.id },
      include: { attendanceSpans: { take: 1 } },
    }),
    prisma.member.count({ where: { verificationStatus: "verified" } }),
    prisma.verificationRequest.count({
      where: { method: "vouch", status: "pending" },
    }),
  ]);

  const label = record
    ? deriveLabel(record.role, record.attendanceSpans[0])
    : "";
  const phase2Live = verifiedCount >= PHASE2_MEMBER_THRESHOLD;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">
          Welcome back, {record?.displayName}
        </h1>
        <p className="chip mt-2">{label}</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Tile
          href="/directory"
          title="Find your people"
          body="Search by name, era-overlap, role, class, or city."
        />
        <Tile
          href="/map"
          title="Hall of Flags"
          body="See where Penguins are now — city-level pins."
        />
        <Tile
          href="/library"
          title="Library"
          body="Yearbooks and photos, browsable by era."
        />
        <Tile
          href="/chat"
          title="Cafeteria"
          body="Message friends, or start a chat with everyone from your year."
        />
        <Tile
          href="/vouch"
          title={`Vouch for Penguins${pendingVouchSeekers ? ` (${pendingVouchSeekers})` : ""}`}
          body="Confirm people you remember so they can join."
        />
        <Tile
          href="/settings"
          title="Privacy & settings"
          body="Tagging, map visibility, export, delete."
        />
      </div>

      <div className="card">
        <h2 className="font-medium">Community status</h2>
        <p className="mt-1 text-sm text-deep-700/70">
          {verifiedCount} verified Penguin{verifiedCount === 1 ? "" : "s"} so far.
        </p>
        <p className="mt-2 text-sm text-deep-700/70">
          {phase2Live ? (
            <>Reunions, meetups, and the feed are live. 🎉</>
          ) : (
            <>
              Reunions &amp; the feed switch on at {PHASE2_MEMBER_THRESHOLD}{" "}
              verified members — gated by real numbers, not a date, so they never
              look empty.
            </>
          )}
        </p>
      </div>
    </div>
  );
}

function Tile({
  href,
  title,
  body,
}: {
  href: string;
  title: string;
  body: string;
}) {
  return (
    <Link href={href} className="card transition hover:border-ice-300 hover:shadow">
      <h2 className="font-medium">{title}</h2>
      <p className="mt-1 text-sm text-deep-700/70">{body}</p>
    </Link>
  );
}
