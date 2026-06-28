-- CreateEnum
CREATE TYPE "Role" AS ENUM ('student', 'faculty', 'staff');

-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('pending', 'verified', 'rejected');

-- CreateEnum
CREATE TYPE "MapVisibility" AS ENUM ('city', 'country', 'hidden');

-- CreateEnum
CREATE TYPE "Visibility" AS ENUM ('friends', 'verified_members', 'hidden');

-- CreateEnum
CREATE TYPE "VerificationMethod" AS ENUM ('vouch', 'era_corroboration');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "FriendshipStatus" AS ENUM ('pending', 'accepted');

-- CreateEnum
CREATE TYPE "ProfileEntryKind" AS ENUM ('work', 'education');

-- CreateEnum
CREATE TYPE "ArchiveType" AS ENUM ('yearbook', 'photo');

-- CreateEnum
CREATE TYPE "ChatThreadType" AS ENUM ('dm', 'group');

-- CreateEnum
CREATE TYPE "MessageRequestStatus" AS ENUM ('pending', 'accepted', 'declined');

-- CreateEnum
CREATE TYPE "GatheringType" AS ENUM ('reunion', 'meetup');

-- CreateEnum
CREATE TYPE "GatheringStatus" AS ENUM ('proposed', 'gathering_interest', 'confirmed', 'happened', 'archived');

-- CreateEnum
CREATE TYPE "InterestStatus" AS ENUM ('interested', 'attending');

-- CreateEnum
CREATE TYPE "FeedLane" AS ENUM ('announcement', 'general');

-- CreateTable
CREATE TABLE "Member" (
    "id" TEXT NOT NULL,
    "authProviderId" TEXT,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT,
    "emailVerified" TIMESTAMP(3),
    "legalName" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "isPseudonymous" BOOLEAN NOT NULL DEFAULT false,
    "role" "Role" NOT NULL,
    "verificationStatus" "VerificationStatus" NOT NULL DEFAULT 'pending',
    "verifiedAt" TIMESTAMP(3),
    "homeCity" TEXT,
    "homeCountry" TEXT,
    "homeLat" DOUBLE PRECISION,
    "homeLng" DOUBLE PRECISION,
    "cityUpdatedAt" TIMESTAMP(3),
    "mapVisibility" "MapVisibility" NOT NULL DEFAULT 'city',
    "allowFaceTagging" BOOLEAN NOT NULL DEFAULT true,
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Member_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceSpan" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "startYear" INTEGER NOT NULL,
    "endYear" INTEGER NOT NULL,
    "entryGrade" TEXT,
    "exitGrade" TEXT,
    "graduated" BOOLEAN NOT NULL DEFAULT false,
    "divisions" TEXT[],
    "subjects" TEXT[],
    "gradesTaught" TEXT[],
    "staffRole" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AttendanceSpan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "accessToken" TEXT,
    "refreshToken" TEXT,
    "expiresAt" INTEGER,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vouch" (
    "id" TEXT NOT NULL,
    "voucherId" TEXT NOT NULL,
    "voucheeId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Vouch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationRequest" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "method" "VerificationMethod" NOT NULL,
    "corroborationDetails" TEXT,
    "status" "RequestStatus" NOT NULL DEFAULT 'pending',
    "reviewedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VerificationRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Friendship" (
    "id" TEXT NOT NULL,
    "requesterId" TEXT NOT NULL,
    "addresseeId" TEXT NOT NULL,
    "status" "FriendshipStatus" NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Friendship_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProfileEntry" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "kind" "ProfileEntryKind" NOT NULL,
    "org" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "startYear" INTEGER,
    "endYear" INTEGER,
    "visibility" "Visibility" NOT NULL DEFAULT 'verified_members',

    CONSTRAINT "ProfileEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ArchiveItem" (
    "id" TEXT NOT NULL,
    "uploaderId" TEXT NOT NULL,
    "type" "ArchiveType" NOT NULL,
    "title" TEXT NOT NULL,
    "year" INTEGER,
    "yearRangeStart" INTEGER,
    "yearRangeEnd" INTEGER,
    "roomTag" TEXT,
    "imageRef" TEXT NOT NULL,
    "visibility" "Visibility" NOT NULL DEFAULT 'verified_members',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ArchiveItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ArchiveTag" (
    "id" TEXT NOT NULL,
    "archiveItemId" TEXT NOT NULL,
    "taggedMemberId" TEXT,
    "label" TEXT,
    "addedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ArchiveTag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatThread" (
    "id" TEXT NOT NULL,
    "type" "ChatThreadType" NOT NULL,
    "name" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChatThread_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatMembership" (
    "id" TEXT NOT NULL,
    "threadId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastReadAt" TIMESTAMP(3),

    CONSTRAINT "ChatMembership_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Message" (
    "id" TEXT NOT NULL,
    "threadId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MessageRequest" (
    "id" TEXT NOT NULL,
    "fromId" TEXT NOT NULL,
    "toId" TEXT NOT NULL,
    "status" "MessageRequestStatus" NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MessageRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Gathering" (
    "id" TEXT NOT NULL,
    "type" "GatheringType" NOT NULL,
    "title" TEXT NOT NULL,
    "eraStart" INTEGER,
    "eraEnd" INTEGER,
    "city" TEXT,
    "proposedBy" TEXT NOT NULL,
    "status" "GatheringStatus" NOT NULL DEFAULT 'proposed',
    "interestThreshold" INTEGER NOT NULL DEFAULT 5,
    "eventDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Gathering_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GatheringInterest" (
    "id" TEXT NOT NULL,
    "gatheringId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "status" "InterestStatus" NOT NULL DEFAULT 'interested',
    "isPrivate" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "GatheringInterest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeedPost" (
    "id" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "lane" "FeedLane" NOT NULL DEFAULT 'general',
    "visibility" "Visibility" NOT NULL DEFAULT 'verified_members',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FeedPost_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeedComment" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FeedComment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeedReaction" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "emoji" TEXT NOT NULL,

    CONSTRAINT "FeedReaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreItem" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "imageRef" TEXT,
    "printProviderRef" TEXT,
    "priceCents" INTEGER NOT NULL,

    CONSTRAINT "StoreItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MentorshipOffer" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "areas" TEXT[],
    "open" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "MentorshipOffer_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Member_email_key" ON "Member"("email");

-- CreateIndex
CREATE INDEX "Member_role_idx" ON "Member"("role");

-- CreateIndex
CREATE INDEX "Member_verificationStatus_idx" ON "Member"("verificationStatus");

-- CreateIndex
CREATE INDEX "Member_homeCity_homeCountry_idx" ON "Member"("homeCity", "homeCountry");

-- CreateIndex
CREATE INDEX "AttendanceSpan_memberId_idx" ON "AttendanceSpan"("memberId");

-- CreateIndex
CREATE INDEX "AttendanceSpan_startYear_endYear_idx" ON "AttendanceSpan"("startYear", "endYear");

-- CreateIndex
CREATE INDEX "Account_memberId_idx" ON "Account"("memberId");

-- CreateIndex
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON "Account"("provider", "providerAccountId");

-- CreateIndex
CREATE INDEX "Vouch_voucheeId_idx" ON "Vouch"("voucheeId");

-- CreateIndex
CREATE UNIQUE INDEX "Vouch_voucherId_voucheeId_key" ON "Vouch"("voucherId", "voucheeId");

-- CreateIndex
CREATE INDEX "VerificationRequest_memberId_idx" ON "VerificationRequest"("memberId");

-- CreateIndex
CREATE INDEX "VerificationRequest_status_idx" ON "VerificationRequest"("status");

-- CreateIndex
CREATE INDEX "Friendship_addresseeId_idx" ON "Friendship"("addresseeId");

-- CreateIndex
CREATE UNIQUE INDEX "Friendship_requesterId_addresseeId_key" ON "Friendship"("requesterId", "addresseeId");

-- CreateIndex
CREATE INDEX "ProfileEntry_memberId_idx" ON "ProfileEntry"("memberId");

-- CreateIndex
CREATE INDEX "ArchiveItem_year_idx" ON "ArchiveItem"("year");

-- CreateIndex
CREATE INDEX "ArchiveItem_roomTag_idx" ON "ArchiveItem"("roomTag");

-- CreateIndex
CREATE INDEX "ArchiveTag_archiveItemId_idx" ON "ArchiveTag"("archiveItemId");

-- CreateIndex
CREATE INDEX "ArchiveTag_taggedMemberId_idx" ON "ArchiveTag"("taggedMemberId");

-- CreateIndex
CREATE INDEX "ChatMembership_memberId_idx" ON "ChatMembership"("memberId");

-- CreateIndex
CREATE UNIQUE INDEX "ChatMembership_threadId_memberId_key" ON "ChatMembership"("threadId", "memberId");

-- CreateIndex
CREATE INDEX "Message_threadId_createdAt_idx" ON "Message"("threadId", "createdAt");

-- CreateIndex
CREATE INDEX "MessageRequest_toId_idx" ON "MessageRequest"("toId");

-- CreateIndex
CREATE UNIQUE INDEX "MessageRequest_fromId_toId_key" ON "MessageRequest"("fromId", "toId");

-- CreateIndex
CREATE UNIQUE INDEX "GatheringInterest_gatheringId_memberId_key" ON "GatheringInterest"("gatheringId", "memberId");

-- CreateIndex
CREATE UNIQUE INDEX "FeedReaction_postId_memberId_emoji_key" ON "FeedReaction"("postId", "memberId", "emoji");

-- AddForeignKey
ALTER TABLE "AttendanceSpan" ADD CONSTRAINT "AttendanceSpan_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vouch" ADD CONSTRAINT "Vouch_voucherId_fkey" FOREIGN KEY ("voucherId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vouch" ADD CONSTRAINT "Vouch_voucheeId_fkey" FOREIGN KEY ("voucheeId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VerificationRequest" ADD CONSTRAINT "VerificationRequest_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VerificationRequest" ADD CONSTRAINT "VerificationRequest_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "Member"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Friendship" ADD CONSTRAINT "Friendship_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Friendship" ADD CONSTRAINT "Friendship_addresseeId_fkey" FOREIGN KEY ("addresseeId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProfileEntry" ADD CONSTRAINT "ProfileEntry_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArchiveItem" ADD CONSTRAINT "ArchiveItem_uploaderId_fkey" FOREIGN KEY ("uploaderId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArchiveTag" ADD CONSTRAINT "ArchiveTag_archiveItemId_fkey" FOREIGN KEY ("archiveItemId") REFERENCES "ArchiveItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArchiveTag" ADD CONSTRAINT "ArchiveTag_taggedMemberId_fkey" FOREIGN KEY ("taggedMemberId") REFERENCES "Member"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArchiveTag" ADD CONSTRAINT "ArchiveTag_addedBy_fkey" FOREIGN KEY ("addedBy") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatThread" ADD CONSTRAINT "ChatThread_createdBy_fkey" FOREIGN KEY ("createdBy") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMembership" ADD CONSTRAINT "ChatMembership_threadId_fkey" FOREIGN KEY ("threadId") REFERENCES "ChatThread"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMembership" ADD CONSTRAINT "ChatMembership_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_threadId_fkey" FOREIGN KEY ("threadId") REFERENCES "ChatThread"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MessageRequest" ADD CONSTRAINT "MessageRequest_fromId_fkey" FOREIGN KEY ("fromId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MessageRequest" ADD CONSTRAINT "MessageRequest_toId_fkey" FOREIGN KEY ("toId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GatheringInterest" ADD CONSTRAINT "GatheringInterest_gatheringId_fkey" FOREIGN KEY ("gatheringId") REFERENCES "Gathering"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FeedComment" ADD CONSTRAINT "FeedComment_postId_fkey" FOREIGN KEY ("postId") REFERENCES "FeedPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FeedReaction" ADD CONSTRAINT "FeedReaction_postId_fkey" FOREIGN KEY ("postId") REFERENCES "FeedPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;
