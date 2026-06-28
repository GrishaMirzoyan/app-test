import { requireMember } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import OnboardingForm from "@/components/OnboardingForm";

export default async function OnboardingPage() {
  const me = await requireMember();
  const record = await prisma.member.findUnique({
    where: { id: me.id },
    include: { attendanceSpans: { take: 1 } },
  });

  return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="text-2xl font-semibold">Tell us when you were a Penguin</h1>
      <p className="mt-2 text-sm text-deep-700/70">
        This is the spine of everything — your era is how others find you. Your
        location is stored at city level only.
      </p>
      <div className="mt-6">
        <OnboardingForm
          initial={{
            role: record?.role ?? "student",
            displayName: record?.displayName ?? "",
            isPseudonymous: record?.isPseudonymous ?? false,
            homeCity: record?.homeCity ?? "",
            homeCountry: record?.homeCountry ?? "",
            mapVisibility: record?.mapVisibility ?? "city",
            span: record?.attendanceSpans[0]
              ? {
                  startYear: record.attendanceSpans[0].startYear,
                  endYear: record.attendanceSpans[0].endYear,
                  graduated: record.attendanceSpans[0].graduated,
                }
              : undefined,
          }}
        />
      </div>
    </main>
  );
}
