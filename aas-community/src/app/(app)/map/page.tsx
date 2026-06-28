import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import { deriveLabel } from "@/lib/labels";
import MapView, { type CityGroup } from "@/components/MapView";
import Link from "next/link";

// Hall of Flags (§4.5): world map of members by home_city, respecting
// map_visibility. City-level pins ONLY (hard constraint §1).
export default async function MapPage() {
  const me = await requireVerified();

  const members = await prisma.member.findMany({
    where: { verificationStatus: "verified", mapVisibility: { not: "hidden" } },
    include: { attendanceSpans: { take: 1, orderBy: { startYear: "asc" } } },
  });

  // City-pinned members (map_visibility = city, with a known centroid).
  const cityMap = new Map<string, CityGroup>();
  // Country tally includes both city- and country-visibility members.
  const countryTally = new Map<string, number>();

  for (const m of members) {
    if (m.homeCountry) {
      countryTally.set(m.homeCountry, (countryTally.get(m.homeCountry) ?? 0) + 1);
    }
    if (m.mapVisibility !== "city") continue;
    if (m.homeLat == null || m.homeLng == null || !m.homeCity) continue;
    const key = `${m.homeCity}|${m.homeCountry}`;
    if (!cityMap.has(key)) {
      cityMap.set(key, {
        city: m.homeCity,
        country: m.homeCountry ?? "",
        lat: m.homeLat,
        lng: m.homeLng,
        members: [],
      });
    }
    cityMap.get(key)!.members.push({
      id: m.id,
      name: m.displayName,
      label: deriveLabel(m.role, m.attendanceSpans[0]),
    });
  }

  const groups = [...cityMap.values()].sort(
    (a, b) => b.members.length - a.members.length,
  );
  const countries = [...countryTally.entries()].sort((a, b) => b[1] - a[1]);

  // Editable-home-city nudge (§4.5): prompt if the pin is stale (>180 days).
  const myRecord = await prisma.member.findUnique({
    where: { id: me.id },
    select: { homeCity: true, cityUpdatedAt: true },
  });
  const stale =
    myRecord?.cityUpdatedAt != null &&
    Date.now() - myRecord.cityUpdatedAt.getTime() > 180 * 24 * 3600 * 1000;

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-semibold">Hall of Flags</h1>

      {stale && (
        <div className="card flex items-center justify-between bg-ice-50">
          <p className="text-sm">Still in {myRecord?.homeCity}?</p>
          <Link className="btn-ghost" href="/settings">
            Update my city
          </Link>
        </div>
      )}

      <MapView groups={groups} />

      <div className="card">
        <h2 className="font-medium">By country</h2>
        <div className="mt-3 flex flex-wrap gap-2">
          {countries.map(([c, n]) => (
            <Link
              key={c}
              href={`/directory?city=`}
              className="chip"
              title="Open the directory"
            >
              {c} · {n}
            </Link>
          ))}
          {countries.length === 0 && (
            <p className="text-sm text-deep-700/60">No locations shared yet.</p>
          )}
        </div>
      </div>
    </div>
  );
}
