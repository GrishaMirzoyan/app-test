import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import Threshold from "@/components/Threshold";
import { currentMember } from "@/lib/gate";
import { prisma } from "@/lib/prisma";

// The threshold and the router. Decides where a member lands:
//   not signed in     → Threshold (login)
//   not onboarded     → /onboarding
//   not verified      → /verify
//   verified          → /dashboard
export default async function Home() {
  const member = await currentMember();

  if (!member) {
    const jar = await cookies();
    const returning = jar
      .getAll()
      .some((c) => c.name.includes("authjs") || c.name.includes("next-auth"));
    return (
      <Threshold
        returning={returning}
        oauth={{
          google: !!process.env.AUTH_GOOGLE_ID,
          apple: !!process.env.AUTH_APPLE_ID,
        }}
      />
    );
  }

  const record = await prisma.member.findUnique({
    where: { id: member.id },
    include: { attendanceSpans: true },
  });
  if (!record) redirect("/");

  const onboarded = record.attendanceSpans.length > 0 && !!record.homeCity;
  if (!onboarded) redirect("/onboarding");
  if (record.verificationStatus !== "verified") redirect("/verify");
  redirect("/dashboard");
}
