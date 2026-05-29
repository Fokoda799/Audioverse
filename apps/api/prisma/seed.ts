import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}

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
    },
    {
      email: 'john@app.com',
      password: 'User@123',
      name: 'John Doe',
      role: UserRole.USER,
    },
    {
      email: 'jane@app.com',
      password: 'User@123',
      name: 'Jane Smith',
      role: UserRole.USER,
    },
    {
      email: 'bob@app.com',
      password: 'User@123',
      name: 'Bob Johnson',
      role: UserRole.USER,
    },
  ];

  for (const user of users) {
    const hashedPassword = await bcrypt.hash(user.password, SALT_ROUNDS);

    await prisma.users.upsert({
      where: { email: user.email },
      update: {},
      create: {
        email: user.email,
        name: user.name,
        role: user.role,
        passwordHash: hashedPassword,
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
