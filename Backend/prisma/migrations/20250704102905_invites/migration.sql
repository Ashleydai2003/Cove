-- CreateTable
CREATE TABLE "Invite" (
    "id" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "coveId" TEXT NOT NULL,
    "sentByUserId" TEXT NOT NULL,
    "message" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "isOpened" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Invite_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Invite_phoneNumber_idx" ON "Invite"("phoneNumber");

-- CreateIndex
CREATE INDEX "Invite_coveId_idx" ON "Invite"("coveId");

-- CreateIndex
CREATE UNIQUE INDEX "Invite_phoneNumber_coveId_key" ON "Invite"("phoneNumber", "coveId");

-- AddForeignKey
ALTER TABLE "Invite" ADD CONSTRAINT "Invite_coveId_fkey" FOREIGN KEY ("coveId") REFERENCES "Cove"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invite" ADD CONSTRAINT "Invite_sentByUserId_fkey" FOREIGN KEY ("sentByUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
