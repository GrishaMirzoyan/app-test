// Seed the first cohort — the founder is the trust root (§3.3). Dev-only data.
// All seeded accounts use the password "penguin123".

import { PrismaClient, type Role } from "@prisma/client";
import bcrypt from "bcryptjs";
import { cityCentroid } from "../src/lib/cities";

const prisma = new PrismaClient();

// A tiny solid-color PNG (8x8) used as a placeholder archive image.
const PLACEHOLDER_PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAFElEQVR4nGNgYGD4z0AEYBxVSF+FAP5FDvcfRYWgAAAAAElFTkSuQmCC",
  "base64",
);

interface SeedMember {
  email: string;
  legalName: string;
  displayName: string;
  role: Role;
  city: string;
  country: string;
  span: { startYear: number; endYear: number; graduated?: boolean };
  verified: boolean;
  admin?: boolean;
  pseudonymous?: boolean;
  seekingVouch?: boolean;
}

const MEMBERS: SeedMember[] = [
  {
    email: "founder@aas.example",
    legalName: "Mara Lindqvist",
    displayName: "Mara L.",
    role: "staff",
    city: "Amsterdam",
    country: "Netherlands",
    span: { startYear: 1998, endYear: 2010 },
    verified: true,
    admin: true,
  },
  {
    email: "alex@aas.example",
    legalName: "Alexei Romanov",
    displayName: "Alex R.",
    role: "student",
    city: "London",
    country: "United Kingdom",
    span: { startYear: 2003, endYear: 2011, graduated: true },
    verified: true,
  },
  {
    email: "nadia@aas.example",
    legalName: "Nadia Petrova",
    displayName: "icewing", // pseudonym
    role: "student",
    city: "Tbilisi",
    country: "Georgia",
    span: { startYear: 2005, endYear: 2011, graduated: true },
    verified: true,
    pseudonymous: true,
  },
  {
    email: "james@aas.example",
    legalName: "James Okafor",
    displayName: "Mr. Okafor",
    role: "faculty",
    city: "Berlin",
    country: "Germany",
    span: { startYear: 2008, endYear: 2016 },
    verified: true,
  },
  {
    email: "sara@aas.example",
    legalName: "Sara Kim",
    displayName: "Sara K.",
    role: "student",
    city: "New York",
    country: "United States",
    span: { startYear: 2007, endYear: 2013, graduated: true },
    verified: true,
  },
  {
    email: "dmitry@aas.example",
    legalName: "Dmitry Volkov",
    displayName: "Dmitry V.",
    role: "student",
    city: "Dubai",
    country: "United Arab Emirates",
    span: { startYear: 2009, endYear: 2015, graduated: true },
    verified: true,
  },
  // Pending members seeking vouches (so the Vouch page isn't empty).
  {
    email: "lena@aas.example",
    legalName: "Lena Fischer",
    displayName: "Lena F.",
    role: "student",
    city: "Geneva",
    country: "Switzerland",
    span: { startYear: 2006, endYear: 2012, graduated: true },
    verified: false,
    seekingVouch: true,
  },
  {
    email: "tom@aas.example",
    legalName: "Tom Bauer",
    displayName: "Tom B.",
    role: "student",
    city: "Toronto",
    country: "Canada",
    span: { startYear: 2004, endYear: 2010, graduated: true },
    verified: false,
    seekingVouch: true,
  },
];

async function main() {
  const passwordHash = await bcrypt.hash("penguin123", 12);

  const byEmail = new Map<string, string>();

  for (const m of MEMBERS) {
    const centroid = cityCentroid(m.city, m.country);
    const member = await prisma.member.upsert({
      where: { email: m.email },
      update: {},
      create: {
        email: m.email,
        passwordHash,
        legalName: m.legalName,
        displayName: m.displayName,
        isPseudonymous: !!m.pseudonymous,
        role: m.role,
        verificationStatus: m.verified ? "verified" : "pending",
        verifiedAt: m.verified ? new Date() : null,
        isAdmin: !!m.admin,
        homeCity: m.city,
        homeCountry: m.country,
        homeLat: centroid?.lat ?? null,
        homeLng: centroid?.lng ?? null,
        cityUpdatedAt: new Date(),
        attendanceSpans: {
          create: {
            startYear: m.span.startYear,
            endYear: m.span.endYear,
            graduated: m.role === "student" ? !!m.span.graduated : false,
            divisions: m.role === "student" ? ["high"] : [],
            subjects: m.role === "faculty" ? ["History"] : [],
            gradesTaught: m.role === "faculty" ? ["9", "10", "11"] : [],
            entryGrade: m.role === "student" ? "7" : null,
            exitGrade: m.role === "student" ? "12" : null,
            staffRole: m.role === "staff" ? "Head of School" : null,
          },
        },
      },
    });
    byEmail.set(m.email, member.id);

    if (m.seekingVouch) {
      const existing = await prisma.verificationRequest.findFirst({
        where: { memberId: member.id, status: "pending" },
      });
      if (!existing) {
        await prisma.verificationRequest.create({
          data: { memberId: member.id, method: "vouch" },
        });
      }
    }
  }

  // A friendship + a DM with messages so the Cafeteria isn't empty.
  const alex = byEmail.get("alex@aas.example")!;
  const nadia = byEmail.get("nadia@aas.example")!;
  await prisma.friendship.upsert({
    where: { requesterId_addresseeId: { requesterId: alex, addresseeId: nadia } },
    update: { status: "accepted" },
    create: { requesterId: alex, addresseeId: nadia, status: "accepted" },
  });

  const existingDm = await prisma.chatThread.findFirst({
    where: {
      type: "dm",
      AND: [
        { memberships: { some: { memberId: alex } } },
        { memberships: { some: { memberId: nadia } } },
      ],
    },
  });
  if (!existingDm) {
    const dm = await prisma.chatThread.create({
      data: {
        type: "dm",
        createdBy: alex,
        memberships: { create: [{ memberId: alex }, { memberId: nadia }] },
      },
    });
    await prisma.message.createMany({
      data: [
        { threadId: dm.id, senderId: alex, body: "Penguin! Is that really you?" },
        { threadId: dm.id, senderId: nadia, body: "Always. Hall of Flags forever 🐧" },
      ],
    });
  }

  // A couple of archive items, browsable by era.
  const founder = byEmail.get("founder@aas.example")!;
  const archiveCount = await prisma.archiveItem.count();
  if (archiveCount === 0) {
    const { putObject } = await import("../src/lib/storage");
    const a = await putObject(PLACEHOLDER_PNG, "image/png");
    const b = await putObject(PLACEHOLDER_PNG, "image/png");
    await prisma.archiveItem.create({
      data: {
        uploaderId: founder,
        type: "photo",
        title: "Hall of Flags, winter assembly",
        year: 2011,
        roomTag: "Hall of Flags",
        imageRef: a.key,
        tags: { create: [{ label: "Hall of Flags", addedBy: founder }] },
      },
    });
    await prisma.archiveItem.create({
      data: {
        uploaderId: founder,
        type: "yearbook",
        title: "Yearbook cover",
        yearRangeStart: 2003,
        yearRangeEnd: 2004,
        imageRef: b.key,
      },
    });
  }

  console.log(`Seeded ${MEMBERS.length} members. Login password: penguin123`);
  console.log("Admin / trust root: founder@aas.example");
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
