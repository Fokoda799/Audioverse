/*
  Warnings:

  - A unique constraint covering the columns `[sortOrder]` on the table `Category` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Author" ALTER COLUMN "avatarUrl" DROP NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Category_sortOrder_key" ON "Category"("sortOrder");
