/*
  Warnings:

  - You are about to drop the column `intentionAId` on the `Match` table. All the data in the column will be lost.
  - You are about to drop the column `intentionBId` on the `Match` table. All the data in the column will be lost.
  - You are about to drop the column `userAId` on the `Match` table. All the data in the column will be lost.
  - You are about to drop the column `userBId` on the `Match` table. All the data in the column will be lost.
  - Added the required column `groupSize` to the `Match` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "public"."Match" DROP CONSTRAINT "Match_intentionAId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Match" DROP CONSTRAINT "Match_intentionBId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Match" DROP CONSTRAINT "Match_userAId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Match" DROP CONSTRAINT "Match_userBId_fkey";

-- DropIndex
DROP INDEX "public"."Match_userAId_idx";

-- DropIndex
DROP INDEX "public"."Match_userBId_idx";

-- CreateTable first
CREATE TABLE "public"."MatchMember" (
    "id" TEXT NOT NULL,
    "matchId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "intentionId" TEXT NOT NULL,

    CONSTRAINT "MatchMember_pkey" PRIMARY KEY ("id")
);

-- Migrate existing data to new structure
-- Create MatchMember entries for existing matches
INSERT INTO "public"."MatchMember" ("id", "matchId", "userId", "intentionId")
SELECT 
  gen_random_uuid()::text as "id",
  "id" as "matchId",
  "userAId" as "userId",
  "intentionAId" as "intentionId"
FROM "public"."Match"
UNION ALL
SELECT 
  gen_random_uuid()::text as "id",
  "id" as "matchId",
  "userBId" as "userId",
  "intentionBId" as "intentionId"
FROM "public"."Match";

-- Add groupSize column with default value
ALTER TABLE "public"."Match" ADD COLUMN "groupSize" INTEGER NOT NULL DEFAULT 2;

-- AlterTable - drop old columns
ALTER TABLE "public"."Match" DROP COLUMN "intentionAId",
DROP COLUMN "intentionBId",
DROP COLUMN "userAId",
DROP COLUMN "userBId";

-- CreateIndex
CREATE INDEX "MatchMember_matchId_idx" ON "public"."MatchMember"("matchId");

-- CreateIndex
CREATE INDEX "MatchMember_userId_idx" ON "public"."MatchMember"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "MatchMember_matchId_userId_key" ON "public"."MatchMember"("matchId", "userId");

-- AddForeignKey
ALTER TABLE "public"."MatchMember" ADD CONSTRAINT "MatchMember_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "public"."Match"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MatchMember" ADD CONSTRAINT "MatchMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MatchMember" ADD CONSTRAINT "MatchMember_intentionId_fkey" FOREIGN KEY ("intentionId") REFERENCES "public"."Intention"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
