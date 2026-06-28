import { requireMember } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import SettingsForm from "@/components/SettingsForm";
import ProfileEntriesManager from "@/components/ProfileEntriesManager";
import AccountActions from "@/components/AccountActions";

// Settings note: this page only requires sign-in (not verification) so a member
// can always reach Export & Delete (§1).
export default async function SettingsPage() {
  const me = await requireMember();
  const member = await prisma.member.findUnique({
    where: { id: me.id },
    include: { profileEntries: { orderBy: { startYear: "desc" } } },
  });
  if (!member) return null;

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <h1 className="text-2xl font-semibold">Settings</h1>

      <SettingsForm
        initial={{
          displayName: member.displayName,
          isPseudonymous: member.isPseudonymous,
          allowFaceTagging: member.allowFaceTagging,
          mapVisibility: member.mapVisibility,
          homeCity: member.homeCity ?? "",
          homeCountry: member.homeCountry ?? "",
        }}
      />

      <ProfileEntriesManager
        entries={member.profileEntries.map((e) => ({
          id: e.id,
          kind: e.kind,
          org: e.org,
          title: e.title,
          startYear: e.startYear,
          endYear: e.endYear,
          visibility: e.visibility,
        }))}
      />

      <AccountActions />
    </div>
  );
}
