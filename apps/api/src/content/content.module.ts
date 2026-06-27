import { Module } from "@nestjs/common";
import { ContentController } from "./content.controller";
import { PrismaModule } from "@app/prisma/prisma.module";
import { StorageModule } from "@app/storage/storage.module";
import { ContentService } from "./content.service";
import { FavoritesModule } from "@app/favorites/favorites.module";


@Module({
    imports: [
        PrismaModule,
        StorageModule,
        FavoritesModule,
    ],
    controllers: [ContentController],
    providers: [ContentService],
    exports: [ContentService]
})
export class ContentModule {}
