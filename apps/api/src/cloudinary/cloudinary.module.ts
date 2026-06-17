// A global NestJS module that initializes the Cloudinary SDK once
// and makes it available everywhere via dependency injection.

import { Global, Module }    from '@nestjs/common';
import { ConfigService }     from '@nestjs/config';
import { v2 as cloudinary }  from 'cloudinary';

// The injection token — used anywhere you need the Cloudinary instance
export const CLOUDINARY = 'CLOUDINARY';

@Global() // ← Available everywhere without re-importing
@Module({
    providers: [
        ConfigService,
        {
            provide:    CLOUDINARY,
            inject:     [ConfigService],
            useFactory: (config: ConfigService) => {
                // Configure the SDK with your credentials from .env
                // This runs once at app startup
                cloudinary.config({
                cloud_name: config.getOrThrow('CLOUDINARY_CLOUD_NAME'),
                api_key:    config.getOrThrow('CLOUDINARY_API_KEY'),
                api_secret: config.getOrThrow('CLOUDINARY_API_SECRET'),
                });

                return cloudinary;
            },
        },
    ],
    exports: [CLOUDINARY],
})
export class CloudinaryModule {}
