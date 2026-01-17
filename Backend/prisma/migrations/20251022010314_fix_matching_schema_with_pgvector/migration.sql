/*
  Warnings:

  - Changed the type of `value` on the `SurveyResponse` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Dropped unique constraint on `Intention.userId` to allow multiple intentions per user
  - Dropped unique constraint on `Match.userAId_userBId` to enforce ordered pairs via CHECK constraint

*/

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- DropIndex
DROP INDEX IF EXISTS "public"."Intention_userId_key";

-- DropIndex
DROP INDEX IF EXISTS "public"."Match_userAId_userBId_key";

-- AlterTable: Add intentEmbedding column (384 dimensions for e5-small embeddings)
ALTER TABLE "public"."Intention" ADD COLUMN IF NOT EXISTS "intentEmbedding" vector(384);

-- AlterTable: Change SurveyResponse.value from String to Json
ALTER TABLE "public"."SurveyResponse" DROP COLUMN "value",
ADD COLUMN     "value" JSONB NOT NULL;

-- Create partial unique index: ONE ACTIVE INTENTION PER USER
-- This allows multiple intentions per user, but only one can be 'active' at a time
CREATE UNIQUE INDEX IF NOT EXISTS one_active_intention_per_user
ON "public"."Intention"("userId")
WHERE "status" = 'active';

-- Enforce symmetric uniqueness for user pairs by ordering userAId < userBId
ALTER TABLE "public"."Match"
  DROP CONSTRAINT IF EXISTS match_pair_order;

ALTER TABLE "public"."Match"
  ADD CONSTRAINT match_pair_order CHECK ("userAId" < "userBId");

-- Unique pair index (only one row per ordered (A,B) pair)
DROP INDEX IF EXISTS match_unique_pair;
CREATE UNIQUE INDEX match_unique_pair ON "public"."Match"("userAId","userBId");

-- Create ivfflat index for fast ANN search on intention embeddings
-- Lists parameter can be tuned based on data size (rule of thumb: sqrt(n_rows))
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'intention_embedding_ivfflat'
      AND n.nspname = 'public'
  ) THEN
    CREATE INDEX intention_embedding_ivfflat
      ON "public"."Intention" USING ivfflat ("intentEmbedding" vector_cosine_ops)
      WITH (lists = 100);
  END IF;
END$$;

-- Analyze table for ivfflat to build proper clusters
ANALYZE "public"."Intention";
