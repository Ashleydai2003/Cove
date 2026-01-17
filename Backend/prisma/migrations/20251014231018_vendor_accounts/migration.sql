-- CreateEnum
CREATE TYPE "public"."VendorRole" AS ENUM ('MEMBER', 'ADMIN');

-- DropForeignKey
ALTER TABLE "public"."Event" DROP CONSTRAINT "Event_coveId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Event" DROP CONSTRAINT "Event_hostId_fkey";

-- AlterTable
ALTER TABLE "public"."Event" ADD COLUMN     "vendorId" TEXT,
ALTER COLUMN "coveId" DROP NOT NULL,
ALTER COLUMN "hostId" DROP NOT NULL;

-- CreateTable
CREATE TABLE "public"."Vendor" (
    "id" TEXT NOT NULL,
    "organizationName" TEXT NOT NULL,
    "website" TEXT,
    "primaryContactEmail" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "currentCode" TEXT NOT NULL,
    "codeRotatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdById" TEXT NOT NULL,

    CONSTRAINT "Vendor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."VendorUser" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "phone" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "role" "public"."VendorRole" NOT NULL DEFAULT 'MEMBER',
    "onboarding" BOOLEAN NOT NULL DEFAULT true,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "profilePhotoID" TEXT,
    "fcmToken" TEXT,

    CONSTRAINT "VendorUser_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."VendorImage" (
    "id" TEXT NOT NULL,
    "vendorUserId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VendorImage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Vendor_currentCode_key" ON "public"."Vendor"("currentCode");

-- CreateIndex
CREATE INDEX "Vendor_currentCode_idx" ON "public"."Vendor"("currentCode");

-- CreateIndex
CREATE UNIQUE INDEX "VendorUser_phone_key" ON "public"."VendorUser"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "VendorUser_profilePhotoID_key" ON "public"."VendorUser"("profilePhotoID");

-- CreateIndex
CREATE INDEX "VendorUser_vendorId_idx" ON "public"."VendorUser"("vendorId");

-- CreateIndex
CREATE INDEX "VendorUser_phone_idx" ON "public"."VendorUser"("phone");

-- CreateIndex
CREATE INDEX "Event_vendorId_idx" ON "public"."Event"("vendorId");

-- AddForeignKey
ALTER TABLE "public"."Event" ADD CONSTRAINT "Event_coveId_fkey" FOREIGN KEY ("coveId") REFERENCES "public"."Cove"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Event" ADD CONSTRAINT "Event_hostId_fkey" FOREIGN KEY ("hostId") REFERENCES "public"."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Event" ADD CONSTRAINT "Event_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "public"."Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."VendorUser" ADD CONSTRAINT "VendorUser_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "public"."Vendor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."VendorUser" ADD CONSTRAINT "VendorUser_profilePhotoID_fkey" FOREIGN KEY ("profilePhotoID") REFERENCES "public"."VendorImage"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."VendorImage" ADD CONSTRAINT "VendorImage_vendorUserId_fkey" FOREIGN KEY ("vendorUserId") REFERENCES "public"."VendorUser"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
