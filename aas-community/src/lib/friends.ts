import { prisma } from "./prisma";

// Returns the set of member ids that `memberId` is ACCEPTED friends with.
export async function friendIdsOf(memberId: string): Promise<Set<string>> {
  const rows = await prisma.friendship.findMany({
    where: {
      status: "accepted",
      OR: [{ requesterId: memberId }, { addresseeId: memberId }],
    },
    select: { requesterId: true, addresseeId: true },
  });
  const ids = new Set<string>();
  for (const r of rows) {
    ids.add(r.requesterId === memberId ? r.addresseeId : r.requesterId);
  }
  return ids;
}

export async function areFriends(a: string, b: string): Promise<boolean> {
  if (a === b) return true;
  const f = await prisma.friendship.findFirst({
    where: {
      status: "accepted",
      OR: [
        { requesterId: a, addresseeId: b },
        { requesterId: b, addresseeId: a },
      ],
    },
    select: { id: true },
  });
  return !!f;
}
