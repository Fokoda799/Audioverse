import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error('DATABASE_URL is not set');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main() {
  console.log('🌱 Seeding database...');
  const SALT_ROUNDS = 10;

  const users = [
    {
      email: 'admin@app.com',
      password: 'Admin@123',
      name: 'Admin User',
      role: UserRole.ADMIN,
      profile: {
        displayName: 'Admin',
        bio: 'AudioVerse administrator',
        preferences: {
          theme: 'dark',
          playbackSpeed: 1.0,
          autoplay: true,
          notifications: { newEpisodes: true, followers: true },
        },
      },
    },
    {
      email: 'john@app.com',
      password: 'User@123',
      name: 'John Doe',
      role: UserRole.USER,
      profile: {
        displayName: 'John',
        bio: 'Jazz and true crime enthusiast',
        preferences: {
          theme: 'light',
          playbackSpeed: 1.5,
          autoplay: true,
          notifications: { newEpisodes: true, followers: false },
        },
      },
    },
    {
      email: 'jane@app.com',
      password: 'User@123',
      name: 'Jane Smith',
      role: UserRole.USER,
      profile: {
        displayName: 'Jane',
        bio: 'Podcast lover',
        preferences: {
          theme: 'system',
          playbackSpeed: 1.0,
          autoplay: false,
          notifications: { newEpisodes: true, followers: true },
        },
      },
    },
    {
      email: 'bob@app.com',
      password: 'User@123',
      name: 'Bob Johnson',
      role: UserRole.USER,
      profile: {
        displayName: 'Bob',
        bio: null,
        preferences: {},
      },
    },
  ];

  for (const user of users) {
    const hashedPassword = await bcrypt.hash(user.password, SALT_ROUNDS);

    // Upsert user
    const createdUser = await prisma.users.upsert({
      where: { email: user.email },
      update: {},
      create: {
        email: user.email,
        name: user.name,
        role: user.role,
        passwordHash: hashedPassword,
      },
    });

    // Upsert profile — create if missing, skip if already exists
    // This way re-running the seed never overwrites real user data
    await prisma.userProfile.upsert({
      where: { userId: createdUser.id },
      update: {},  // ← don't overwrite existing profile data on re-seed
      create: {
        userId: createdUser.id,
        displayName: user.profile.displayName,
        bio: user.profile.bio,
        preferences: user.profile.preferences,
      },
    });

    console.log(`✅ Seeded: ${user.email} (${user.role})`);
  }

  console.log('🎉 Seeding complete!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });