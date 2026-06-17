/*
  Warnings:

  - A unique constraint covering the columns `[slug]` on the table `AudioContent` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "AudioContent_slug_key" ON "AudioContent"("slug");
