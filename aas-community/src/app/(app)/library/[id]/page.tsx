import { notFound } from "next/navigation";
import Link from "next/link";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import TagArchive from "@/components/TagArchive";

export default async function ArchiveItemPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  await requireVerified();
  const { id } = await params;

  const item = await prisma.archiveItem.findUnique({
    where: { id },
    include: {
      uploader: { select: { displayName: true } },
      tags: {
        include: {
          taggedMember: {
            select: { id: true, displayName: true, allowFaceTagging: true },
          },
        },
        orderBy: { createdAt: "asc" },
      },
    },
  });
  if (!item) notFound();

  // Tagging opt-out is honored RETROACTIVELY (§1): hide tags of any member who
  // has since turned face tagging off. Free-text (room/name) tags remain.
  const visibleTags = item.tags.filter(
    (t) => !t.taggedMember || t.taggedMember.allowFaceTagging,
  );

  const era =
    item.year ??
    (item.yearRangeStart && item.yearRangeEnd
      ? `${item.yearRangeStart}–${item.yearRangeEnd}`
      : "Undated");

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <Link href="/library" className="text-sm text-deep-700/60 underline">
        ← Library
      </Link>

      <div className="card overflow-hidden p-0">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={`/api/archive/image/${item.imageRef}`}
          alt={item.title}
          className="max-h-[60vh] w-full object-contain bg-deep-900"
        />
        <div className="p-4">
          <h1 className="text-xl font-semibold">{item.title}</h1>
          <p className="mt-1 text-sm text-deep-700/60">
            {item.type} · {era}
            {item.roomTag ? ` · ${item.roomTag}` : ""} · uploaded by{" "}
            {item.uploader.displayName}
          </p>
        </div>
      </div>

      <div className="card">
        <h2 className="font-medium">Tags</h2>
        <div className="mt-2 flex flex-wrap gap-2">
          {visibleTags.length === 0 && (
            <p className="text-sm text-deep-700/60">
              No tags yet — name a face or tag a room.
            </p>
          )}
          {visibleTags.map((t) => (
            <span key={t.id} className="chip">
              {t.taggedMember ? (
                <Link href={`/members/${t.taggedMember.id}`} className="underline">
                  {t.taggedMember.displayName}
                </Link>
              ) : (
                t.label
              )}
            </span>
          ))}
        </div>
        <div className="mt-4">
          <TagArchive archiveItemId={item.id} />
        </div>
      </div>
    </div>
  );
}
