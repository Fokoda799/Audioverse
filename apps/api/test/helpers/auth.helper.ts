import { INestApplication } from '@nestjs/common';
import { JwtService }       from '@nestjs/jwt';
import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

export async function createTestUser(
  app:    INestApplication,
  prisma: PrismaClient,
  role:   UserRole = UserRole.USER,
) {
  const email        = `test-${Date.now()}-${Math.random()}@app.com`;
  const passwordHash = await bcrypt.hash('Test@123', 10);

  const user = await prisma.users.create({
    data: {
      email,
      name:         'Test User',
      role,
      passwordHash,
    },
  });

  // Generate a real JWT the same way your AuthService does
  const jwtService = app.get(JwtService);
  const accessToken = jwtService.sign(
    { sub: user.id, email: user.email },
    { secret: process.env.JWT_SECRET, expiresIn: '15m' },
  );

  return { user, accessToken };
}
