import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@app/prisma/prisma.service';

@Injectable()
export class ProfileService {

    constructor (
        private prisma: PrismaService,
    ) {}

    async me(userId: string) {
        console.log('User id: ' + userId)
        const profile = await this.prisma.userProfile.findFirst({
            where: { userId: userId },
            select: {
                id: true,
                displayName: true,
                avatarUrl: true,
                bio: true,
                preferences: true,
                createdAt: true
            }
        });

        if (!profile) throw new NotFoundException("User not found!");

        return profile;
    }
}
