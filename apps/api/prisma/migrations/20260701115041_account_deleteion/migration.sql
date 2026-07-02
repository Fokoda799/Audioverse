-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'PENDING_DELETION', 'DELETED');

-- AlterTable
ALTER TABLE "Users" ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "scheduledDeletionAt" TIMESTAMP(3),
ADD COLUMN     "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE';
