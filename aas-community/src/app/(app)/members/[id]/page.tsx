import { notFound } from "next/navigation";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { deriveLabel } from "@/lib/labels";
import { canView } from "@/lib/visibility";
import { areFriends } from "@/lib/friends";
import RelationActions from "@/components/RelationActions";

export default async function MemberProfile({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const me = await requireVerified();
  const { id } = await params;

  const member = await prisma.member.findUnique({
    where: { id },
    include: {
      attendanceSpans: { orderBy: { startYear: "asc" } },
      profileEntries: { orderBy: [{ endYear: "desc" }, { startYear: "desc" }] },
    },
  });
  // Verification gate: only verified members are visible profiles.
  if (!member || member.verificationStatus !== "verified") notFound();

  const isSelf = member.id === me.id;
  const friends = isSelf ? true : await areFriends(me.id, member.id);
  const viewer = { id: me.id, isVerified: true };

  // Per-item visibility (§1 two rings) applied to work/education entries.
  const visibleEntries = member.profileEntries.filter((e) =>
    canView(viewer, member.id, e.visibility, friends),
  );

  const span = member.attendanceSpans[0];

  // Relationship state for the action buttons.
  let relation: "self" | "friends" | "pending" | "none" = "none";
  if (isSelf) relation = "self";
  else if (friends) relation = "friends";
  else {
    const pending = await prisma.friendship.findFirst({
      where: {
        status: "pending",
        OR: [
          { requesterId: me.id, addresseeId: member.id },
          { requesterId: member.id, addresseeId: me.id },
        ],
      },
    });
    if (pending) relation = "pending";
  }

  return (
    <div className="mx-auto max-w-2xl space-y-5">
      <div className="card">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-semibold">{member.displayName}</h1>
            <p className="chip mt-2">{deriveLabel(member.role, span)}</p>
          </div>
          {!isSelf && <RelationActions memberId={member.id} relation={relation} />}
          {isSelf && (
            <a className="btn-ghost" href="/settings">
              Edit
            </a>
          )}
        </div>

        {member.mapVisibility !== "hidden" && member.homeCity && (
          <p className="mt-3 text-sm text-deep-700/70">
            📍{" "}
            {member.mapVisibility === "city"
              ? `${member.homeCity}, ${member.homeCountry}`
              : member.homeCountry}
          </p>
        )}
      </div>

      <div className="card">
        <h2 className="font-medium">At AAS</h2>
        <ul className="mt-2 space-y-2 text-sm">
          {member.attendanceSpans.map((s) => (
            <li key={s.id} className="rounded-lg bg-ice-50 p-3">
              <span className="font-medium">
                {s.startYear}–{s.endYear}
              </span>
              {member.role === "student" && (
                <span className="text-deep-700/70">
                  {" "}
                  · grades {s.entryGrade ?? "?"}–{s.exitGrade ?? "?"}
                  {s.divisions.length ? ` · ${s.divisions.join(", ")}` : ""}
                  {s.graduated ? " · graduated" : ""}
                </span>
              )}
              {member.role === "faculty" && (
                <span className="text-deep-700/70">
                  {s.subjects.length ? ` · ${s.subjects.join(", ")}` : ""}
                  {s.gradesTaught.length ? ` · grades ${s.gradesTaught.join(", ")}` : ""}
                </span>
              )}
              {member.role === "staff" && s.staffRole && (
                <span className="text-deep-700/70"> · {s.staffRole}</span>
              )}
            </li>
          ))}
        </ul>
      </div>

      <div className="card">
        <h2 className="font-medium">Work &amp; education</h2>
        {visibleEntries.length === 0 ? (
          <p className="mt-2 text-sm text-deep-700/60">
            {isSelf
              ? "Add work and education in Settings."
              : "Nothing shared with you."}
          </p>
        ) : (
          <ul className="mt-2 space-y-2 text-sm">
            {visibleEntries.map((e) => (
              <li key={e.id} className="rounded-lg bg-ice-50 p-3">
                <span className="font-medium">{e.title}</span> · {e.org}
                <span className="text-deep-700/60">
                  {" "}
                  {e.startYear ?? ""}
                  {e.startYear || e.endYear ? "–" : ""}
                  {e.endYear ?? (e.startYear ? "present" : "")}
                </span>
                {isSelf && <span className="chip ml-2">{e.visibility}</span>}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
