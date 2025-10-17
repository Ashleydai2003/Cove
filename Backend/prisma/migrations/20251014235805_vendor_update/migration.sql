-- DropForeignKey
ALTER TABLE "public"."VendorUser" DROP CONSTRAINT "VendorUser_vendorId_fkey";

-- AlterTable
ALTER TABLE "public"."VendorUser" ALTER COLUMN "vendorId" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "public"."VendorUser" ADD CONSTRAINT "VendorUser_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "public"."Vendor"("id") ON DELETE SET NULL ON UPDATE CASCADE;
