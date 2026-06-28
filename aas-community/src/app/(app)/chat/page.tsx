import Link from "next/link";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import CohortStarter from "@/components/CohortStarter";
import RequestInbox from "@/components/RequestInbox";

// The Cafeteria (§4.7): DMs and group chats, with message requests gating first
// contact and cohort-seeded chats so it never launches empty.
export default async function ChatPage() {
  const me = await requireVerified();

  const memberships = await prisma.chatMembership.findMany({
    where: { memberId: me.id },
    include: {
      thread: {
        include: {
          messages: { orderBy: { createdAt: "desc" }, take: 1 },
          memberships: {
            include: { member: { select: { id: true, displayName: true } } },
          },
        },
      },
    },
  });

  const threads = memberships
    .map((ms) => {
      const t = ms.thread;
      const last = t.messages[0];
      const title =
        t.type === "group"
          ? (t.name ?? "Group")
          : (t.memberships.find((x) => x.memberId !== me.id)?.member.displayName ??
            "Conversation");
      return {
        id: t.id,
        type: t.type,
        title,
        last: last ? last.body : null,
        lastAt: last ? last.createdAt : t.createdAt,
        unread: !!(last && last.senderId !== me.id && (!ms.lastReadAt || last.createdAt > ms.lastReadAt)),
      };
    })
    .sort((a, b) => b.lastAt.getTime() - a.lastAt.getTime());

  const [messageRequests, friendRequests] = await Promise.all([
    prisma.messageRequest.findMany({
      where: { toId: me.id, status: "pending" },
      include: { from: { select: { id: true, displayName: true } } },
    }),
    prisma.friendship.findMany({
      where: { addresseeId: me.id, status: "pending" },
      include: { requester: { select: { id: true, displayName: true } } },
    }),
  ]);

  return (
    <div className="grid gap-5 lg:grid-cols-[2fr_1fr]">
      <div className="space-y-3">
        <h1 className="text-2xl font-semibold">Cafeteria</h1>
        {threads.length === 0 && (
          <p className="card text-sm text-deep-700/60">
            No conversations yet. Start one from someone&apos;s profile, or seed a
            chat with your whole cohort →
          </p>
        )}
        {threads.map((t) => (
          <Link key={t.id} href={`/chat/${t.id}`} className="card block hover:border-ice-300">
            <div className="flex items-center justify-between">
              <p className="font-medium">
                {t.type === "group" ? "👥 " : ""}
                {t.title}
              </p>
              {t.unread && <span className="h-2 w-2 rounded-full bg-deep-800" />}
            </div>
            <p className="mt-1 truncate text-sm text-deep-700/60">
              {t.last ?? "No messages yet"}
            </p>
          </Link>
        ))}
      </div>

      <div className="space-y-4">
        <CohortStarter />
        <RequestInbox
          messageRequests={messageRequests.map((r) => ({
            id: r.id,
            fromName: r.from.displayName,
          }))}
          friendRequests={friendRequests.map((r) => ({
            requesterId: r.requesterId,
            requesterName: r.requester.displayName,
          }))}
        />
      </div>
    </div>
  );
}
