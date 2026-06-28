import Link from "next/link";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { deriveLabel } from "@/lib/labels";
import type { Prisma } from "@prisma/client";

// The Directory (§4.4): search by name; filter by era-overlap, grad year/class,
// role, and city. Shows verified members only and respects map/identity privacy.
export default async function DirectoryPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | undefined>>;
}) {
  const me = await requireVerified();
  const sp = await searchParams;

  const q = sp.q?.trim() ?? "";
  const role = sp.role ?? "";
  const city = sp.city?.trim() ?? "";
  const gradYear = sp.gradYear ? parseInt(sp.gradYear, 10) : undefined;
  const overlap = sp.overlap === "1";

  const myRecord = await prisma.member.findUnique({
    where: { id: me.id },
    include: { attendanceSpans: { take: 1 } },
  });
  const mySpan = myRecord?.attendanceSpans[0];

  const where: Prisma.MemberWhereInput = {
    verificationStatus: "verified",
    id: { not: me.id },
  };
  if (q) where.displayName = { contains: q, mode: "insensitive" };
  if (role) where.role = role as Prisma.MemberWhereInput["role"];
  if (city) where.homeCity = { contains: city, mode: "insensitive" };

  const spanFilters: Prisma.AttendanceSpanWhereInput[] = [];
  if (gradYear) spanFilters.push({ endYear: gradYear });
  // Era-overlap (§2): span intersection with my own span.
  if (overlap && mySpan) {
    spanFilters.push({
      startYear: { lte: mySpan.endYear },
      endYear: { gte: mySpan.startYear },
    });
  }
  if (spanFilters.length) {
    where.attendanceSpans = { some: { AND: spanFilters } };
  }

  const members = await prisma.member.findMany({
    where,
    include: { attendanceSpans: { take: 1, orderBy: { startYear: "asc" } } },
    orderBy: { displayName: "asc" },
    take: 200,
  });

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-semibold">Directory</h1>

      <form className="card grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <label className="label">Name</label>
          <input className="input" name="q" defaultValue={q} placeholder="Search…" />
        </div>
        <div>
          <label className="label">Role</label>
          <select className="input" name="role" defaultValue={role}>
            <option value="">Any</option>
            <option value="student">Alum</option>
            <option value="faculty">Faculty</option>
            <option value="staff">Staff</option>
          </select>
        </div>
        <div>
          <label className="label">City</label>
          <input className="input" name="city" defaultValue={city} placeholder="City" />
        </div>
        <div>
          <label className="label">Class / grad year</label>
          <input
            className="input"
            name="gradYear"
            type="number"
            defaultValue={gradYear ?? ""}
            placeholder="e.g. 2011"
          />
        </div>
        <label className="flex items-center gap-2 text-sm sm:col-span-2">
          <input type="checkbox" name="overlap" value="1" defaultChecked={overlap} />
          Only Penguins who were here when I was {mySpan && `(${mySpan.startYear}–${mySpan.endYear})`}
        </label>
        <div className="flex items-end gap-2 sm:col-span-2 lg:col-span-2">
          <button className="btn" type="submit">
            Search
          </button>
          <Link className="btn-ghost" href="/directory">
            Reset
          </Link>
        </div>
      </form>

      <p className="text-sm text-deep-700/60">
        {members.length} Penguin{members.length === 1 ? "" : "s"}
      </p>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {members.map((m) => (
          <Link key={m.id} href={`/members/${m.id}`} className="card hover:border-ice-300">
            <p className="font-medium">{m.displayName}</p>
            <p className="chip mt-1">{deriveLabel(m.role, m.attendanceSpans[0])}</p>
            {m.mapVisibility !== "hidden" && m.homeCity && (
              <p className="mt-2 text-xs text-deep-700/60">
                {m.mapVisibility === "city"
                  ? `${m.homeCity}, ${m.homeCountry}`
                  : m.homeCountry}
              </p>
            )}
          </Link>
        ))}
      </div>
    </div>
  );
}
