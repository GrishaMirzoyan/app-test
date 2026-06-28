import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { requireVerified } from "@/lib/gate";
import { prisma } from "@/lib/prisma";
import ChatThreadView from "@/components/ChatThreadView";

export default async function ThreadPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const me = await requireVerified();
  const { id } = await params;

  const membership = await prisma.chatMembership.findUnique({
    where: { threadId_memberId: { threadId: id, memberId: me.id } },
  });
  if (!membership) redirect("/chat");

  const thread = await prisma.chatThread.findUnique({
    where: { id },
    include: {
      memberships: { include: { member: { select: { id: true, displayName: true } } } },
    },
  });
  if (!thread) notFound();

  const title =
    thread.type === "group"
      ? (thread.name ?? "Group")
      : (thread.memberships.find((m) => m.memberId !== me.id)?.member.displayName ??
        "Conversation");

  return (
    <div className="mx-auto max-w-2xl">
      <div className="mb-3 flex items-center justify-between">
        <Link href="/chat" className="text-sm text-deep-700/60 underline">
          ← Cafeteria
        </Link>
        <span className="text-xs text-deep-700/60">
          {thread.type === "group"
            ? `${thread.memberships.length} members`
            : ""}
        </span>
      </div>
      <h1 className="mb-3 text-xl font-semibold">{title}</h1>
      <ChatThreadView threadId={id} meId={me.id} />
    </div>
  );
}
