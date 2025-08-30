-- Add PENDING to RSVPStatus enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'PENDING' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'RSVPStatus')
    ) THEN
        ALTER TYPE "RSVPStatus" ADD VALUE 'PENDING';
    END IF;
END $$;

-- Update the default value for the EventRSVP table
ALTER TABLE "EventRSVP" ALTER COLUMN "status" SET DEFAULT 'PENDING'; 