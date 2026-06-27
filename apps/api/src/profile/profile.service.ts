import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@app/prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfileService {

    constructor (
        private prisma: PrismaService,
    ) {}

    async me(profileId: string) {
        const profile = await this.prisma.userProfile.findFirst({
            where: { id: profileId },
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

    async update(profileId: string, dto: UpdateProfileDto) {
        const profile = await this.prisma.userProfile.update({
            where: {id: profileId},
            data: {
                displayName: dto.displayName,
                bio: dto.bio,
                avatarUrl: dto.avatarUrl,
            }
        })

        return profile;
    }
}
