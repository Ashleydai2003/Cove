/*
  Warnings:

  - A unique constraint covering the columns `[coverPhotoID]` on the table `Vendor` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[vendorUserId]` on the table `VendorImage` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[vendorId]` on the table `VendorImage` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE "public"."VendorImage" DROP CONSTRAINT "VendorImage_vendorUserId_fkey";

-- DropForeignKey
ALTER TABLE "public"."VendorUser" DROP CONSTRAINT "VendorUser_profilePhotoID_fkey";

-- AlterTable
ALTER TABLE "public"."Vendor" ADD COLUMN     "coverPhotoID" TEXT;

-- AlterTable
ALTER TABLE "public"."VendorImage" ADD COLUMN     "vendorId" TEXT,
ALTER COLUMN "vendorUserId" DROP NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Vendor_coverPhotoID_key" ON "public"."Vendor"("coverPhotoID");

-- CreateIndex
CREATE UNIQUE INDEX "VendorImage_vendorUserId_key" ON "public"."VendorImage"("vendorUserId");

-- CreateIndex
CREATE UNIQUE INDEX "VendorImage_vendorId_key" ON "public"."VendorImage"("vendorId");

-- AddForeignKey
ALTER TABLE "public"."VendorImage" ADD CONSTRAINT "VendorImage_vendorUserId_fkey" FOREIGN KEY ("vendorUserId") REFERENCES "public"."VendorUser"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."VendorImage" ADD CONSTRAINT "VendorImage_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "public"."Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;
