import { PrismaClient } from '@prisma/client';

export async function cleanDatabase(prisma: PrismaClient) {
    await prisma.favorite.deleteMany();
    await prisma.listeningHistory.deleteMany();
    await prisma.audioContent.deleteMany();
    await prisma.author.deleteMany();
    await prisma.category.deleteMany();
    await prisma.userProfile.deleteMany();
    await prisma.users.deleteMany();
}
