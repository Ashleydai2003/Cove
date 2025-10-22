-- CreateEnum
CREATE TYPE "public"."IntentionStatus" AS ENUM ('active', 'matched', 'expired');

-- CreateEnum
CREATE TYPE "public"."MatchStatus" AS ENUM ('active', 'accepted', 'declined', 'expired');

-- AlterTable
ALTER TABLE "public"."UserProfile" ADD COLUMN     "city" TEXT;

-- CreateTable
CREATE TABLE "public"."SurveyResponse" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "isMustHave" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SurveyResponse_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Intention" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "parsedJson" JSONB NOT NULL,
    "validFrom" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "validUntil" TIMESTAMP(3) NOT NULL,
    "status" "public"."IntentionStatus" NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Intention_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."PoolEntry" (
    "id" TEXT NOT NULL,
    "intentionId" TEXT NOT NULL,
    "tier" INTEGER NOT NULL DEFAULT 0,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastBatchAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PoolEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Match" (
    "id" TEXT NOT NULL,
    "userAId" TEXT NOT NULL,
    "userBId" TEXT NOT NULL,
    "intentionAId" TEXT NOT NULL,
    "intentionBId" TEXT NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "tierUsed" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "status" "public"."MatchStatus" NOT NULL DEFAULT 'active',
    "threadId" TEXT,

    CONSTRAINT "Match_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."MatchFeedback" (
    "id" TEXT NOT NULL,
    "matchId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "matchedOn" TEXT[],
    "wasAccurate" BOOLEAN,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MatchFeedback_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SurveyResponse_userId_idx" ON "public"."SurveyResponse"("userId");

-- CreateIndex
CREATE INDEX "SurveyResponse_questionId_idx" ON "public"."SurveyResponse"("questionId");

-- CreateIndex
CREATE UNIQUE INDEX "SurveyResponse_userId_questionId_key" ON "public"."SurveyResponse"("userId", "questionId");

-- CreateIndex
CREATE UNIQUE INDEX "Intention_userId_key" ON "public"."Intention"("userId");

-- CreateIndex
CREATE INDEX "Intention_userId_idx" ON "public"."Intention"("userId");

-- CreateIndex
CREATE INDEX "Intention_status_idx" ON "public"."Intention"("status");

-- CreateIndex
CREATE INDEX "Intention_validUntil_idx" ON "public"."Intention"("validUntil");

-- CreateIndex
CREATE UNIQUE INDEX "PoolEntry_intentionId_key" ON "public"."PoolEntry"("intentionId");

-- CreateIndex
CREATE INDEX "PoolEntry_tier_idx" ON "public"."PoolEntry"("tier");

-- CreateIndex
CREATE INDEX "PoolEntry_lastBatchAt_idx" ON "public"."PoolEntry"("lastBatchAt");

-- CreateIndex
CREATE INDEX "Match_userAId_idx" ON "public"."Match"("userAId");

-- CreateIndex
CREATE INDEX "Match_userBId_idx" ON "public"."Match"("userBId");

-- CreateIndex
CREATE INDEX "Match_status_idx" ON "public"."Match"("status");

-- CreateIndex
CREATE INDEX "Match_expiresAt_idx" ON "public"."Match"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "Match_userAId_userBId_key" ON "public"."Match"("userAId", "userBId");

-- CreateIndex
CREATE INDEX "MatchFeedback_matchId_idx" ON "public"."MatchFeedback"("matchId");

-- CreateIndex
CREATE INDEX "MatchFeedback_userId_idx" ON "public"."MatchFeedback"("userId");

-- CreateIndex
CREATE INDEX "UserProfile_city_idx" ON "public"."UserProfile"("city");

-- AddForeignKey
ALTER TABLE "public"."SurveyResponse" ADD CONSTRAINT "SurveyResponse_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Intention" ADD CONSTRAINT "Intention_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PoolEntry" ADD CONSTRAINT "PoolEntry_intentionId_fkey" FOREIGN KEY ("intentionId") REFERENCES "public"."Intention"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Match" ADD CONSTRAINT "Match_userAId_fkey" FOREIGN KEY ("userAId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Match" ADD CONSTRAINT "Match_userBId_fkey" FOREIGN KEY ("userBId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Match" ADD CONSTRAINT "Match_intentionAId_fkey" FOREIGN KEY ("intentionAId") REFERENCES "public"."Intention"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Match" ADD CONSTRAINT "Match_intentionBId_fkey" FOREIGN KEY ("intentionBId") REFERENCES "public"."Intention"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MatchFeedback" ADD CONSTRAINT "MatchFeedback_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "public"."Match"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MatchFeedback" ADD CONSTRAINT "MatchFeedback_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
