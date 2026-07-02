-- CreateIndex
CREATE INDEX "AudioContent_categoryId_idx" ON "AudioContent"("categoryId");

-- CreateIndex
CREATE INDEX "AudioContent_authorId_idx" ON "AudioContent"("authorId");

-- CreateIndex
CREATE INDEX "AudioContent_isPublished_idx" ON "AudioContent"("isPublished");

-- CreateIndex
CREATE INDEX "Favorite_userId_idx" ON "Favorite"("userId");

-- CreateIndex
CREATE INDEX "ListeningHistory_userId_lastPlayedAt_idx" ON "ListeningHistory"("userId", "lastPlayedAt");
