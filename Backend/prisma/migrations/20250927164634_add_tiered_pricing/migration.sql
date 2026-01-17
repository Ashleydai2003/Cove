-- CreateTable
CREATE TABLE "EventPricingTier" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "tierType" TEXT NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "maxSpots" INTEGER,
    "currentSpots" INTEGER NOT NULL DEFAULT 0,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventPricingTier_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "Event" ADD COLUMN     "useTieredPricing" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "EventRSVP" ADD COLUMN     "pricePaid" DOUBLE PRECISION,
ADD COLUMN     "pricingTierId" TEXT;

-- CreateIndex
CREATE INDEX "EventRSVP_pricingTierId_idx" ON "EventRSVP"("pricingTierId");

-- CreateIndex
CREATE INDEX "EventPricingTier_eventId_idx" ON "EventPricingTier"("eventId");

-- CreateIndex
CREATE INDEX "EventPricingTier_tierType_idx" ON "EventPricingTier"("tierType");

-- CreateIndex
CREATE UNIQUE INDEX "EventPricingTier_eventId_tierType_key" ON "EventPricingTier"("eventId", "tierType");

-- AddForeignKey
ALTER TABLE "EventRSVP" ADD CONSTRAINT "EventRSVP_pricingTierId_fkey" FOREIGN KEY ("pricingTierId") REFERENCES "EventPricingTier"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventPricingTier" ADD CONSTRAINT "EventPricingTier_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE CASCADE ON UPDATE CASCADE;
