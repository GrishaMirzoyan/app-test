import Link from "next/link";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import UploadArchive from "@/components/UploadArchive";

// Library / archive (§4.6). Browse by era/year as the PRIMARY axis.
function eraOf(item: {
  year: number | null;
  yearRangeStart: number | null;
  yearRangeEnd: number | null;
}): string {
  if (item.year) return String(item.year);
  if (item.yearRangeStart && item.yearRangeEnd)
    return `${item.yearRangeStart}–${item.yearRangeEnd}`;
  return "Undated";
}

export default async function LibraryPage() {
  await requireVerified();

  const items = await prisma.archiveItem.findMany({
    orderBy: [{ year: "desc" }, { yearRangeStart: "desc" }, { createdAt: "desc" }],
    include: { _count: { select: { tags: true } } },
  });

  // Group by era (the primary browsing axis).
  const byEra = new Map<string, typeof items>();
  for (const it of items) {
    const era = eraOf(it);
    if (!byEra.has(era)) byEra.set(era, []);
    byEra.get(era)!.push(it);
  }
  const eras = [...byEra.keys()].sort((a, b) => (a < b ? 1 : -1));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Library</h1>
      </div>
      <p className="text-sm text-deep-700/70">
        Yearbooks and photos of a vanished school — verified-members-only, never
        public. Browse by era; help date, name faces, and tag rooms.
      </p>

      <UploadArchive />

      {eras.length === 0 && (
        <p className="card text-sm text-deep-700/60">
          The archive is empty. Be the first to upload a yearbook or photo.
        </p>
      )}

      {eras.map((era) => (
        <section key={era}>
          <h2 className="mb-2 text-lg font-medium">{era}</h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {byEra.get(era)!.map((it) => (
              <Link
                key={it.id}
                href={`/library/${it.id}`}
                className="card overflow-hidden p-0 hover:border-ice-300"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={`/api/archive/image/${it.imageRef}`}
                  alt={it.title}
                  className="h-36 w-full object-cover"
                />
                <div className="p-3">
                  <p className="text-sm font-medium">{it.title}</p>
                  <p className="mt-1 text-xs text-deep-700/60">
                    {it.type}
                    {it.roomTag ? ` · ${it.roomTag}` : ""} · {it._count.tags} tag
                    {it._count.tags === 1 ? "" : "s"}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
