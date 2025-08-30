-- Update RSVPStatus enum to use PENDING instead of MAYBE and NOT_GOING
-- First, update any existing records to use GOING instead of MAYBE/NOT_GOING
UPDATE "EventRSVP" SET status = 'GOING' WHERE status = 'MAYBE';
UPDATE "EventRSVP" SET status = 'GOING' WHERE status = 'NOT_GOING';

-- Drop the old enum and recreate it
DROP TYPE "RSVPStatus";

-- CreateEnum
CREATE TYPE "RSVPStatus" AS ENUM ('GOING', 'PENDING');

-- Update the default value for the EventRSVP table
ALTER TABLE "EventRSVP" ALTER COLUMN "status" SET DEFAULT 'PENDING'; 