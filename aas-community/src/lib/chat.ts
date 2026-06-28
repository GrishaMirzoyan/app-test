import { prisma } from "./prisma";

// Find the existing 1:1 DM thread between two members, or create one with both
// as members.
export async function findOrCreateDmThread(
  a: string,
  b: string,
): Promise<string> {
  const existing = await prisma.chatThread.findFirst({
    where: {
      type: "dm",
      AND: [
        { memberships: { some: { memberId: a } } },
        { memberships: { some: { memberId: b } } },
      ],
    },
    select: { id: true },
  });
  if (existing) return existing.id;

  const thread = await prisma.chatThread.create({
    data: {
      type: "dm",
      createdBy: a,
      memberships: { create: [{ memberId: a }, { memberId: b }] },
    },
  });
  return thread.id;
}
