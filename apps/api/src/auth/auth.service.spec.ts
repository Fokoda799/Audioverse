import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
  hash: jest.fn(),
}));

describe('AuthService', () => {
  let service: AuthService;

  const prisma = {
    users: {
      create: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
    },
    refreshToken: {
      create: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const jwtService = {
    signAsync: jest.fn(),
  };

  const user = {
    id: 'user-1',
    email: 'reader@example.com',
    name: 'Reader One',
    passwordHash: 'hashed-password',
    role: 'USER',
    avatarUrl: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-02T00:00:00.000Z'),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);

    jest.clearAllMocks();
    process.env.JWT_SECRET = 'access-secret';
    process.env.JWT_REFRESH_SECRET = 'refresh-secret';
  });

  describe('validateUser', () => {
    it('returns the user without passwordHash when credentials are valid', async () => {
      prisma.users.findUnique.mockResolvedValue(user);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.validateUser(user.email, 'correct-password'),
      ).resolves.toEqual({
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        avatarUrl: user.avatarUrl,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      });

      expect(prisma.users.findUnique).toHaveBeenCalledWith({
        where: { email: user.email },
      });
      expect(bcrypt.compare).toHaveBeenCalledWith(
        'correct-password',
        user.passwordHash,
      );
    });

    it('returns null when the user does not exist', async () => {
      prisma.users.findUnique.mockResolvedValue(null);

      await expect(
        service.validateUser('missing@example.com', 'password'),
      ).resolves.toBeNull();

      expect(bcrypt.compare).not.toHaveBeenCalled();
    });

    it('returns null when the password is invalid', async () => {
      prisma.users.findUnique.mockResolvedValue(user);
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.validateUser(user.email, 'wrong-password'),
      ).resolves.toBeNull();
    });
  });

  describe('register', () => {
    const dto: RegisterDto = {
      name: 'Reader One',
      email: 'reader@example.com',
      password: 'plain-password',
    };

    it('creates a user, saves a hashed refresh token, and returns tokens', async () => {
      prisma.users.findUnique.mockResolvedValue(null);
      prisma.users.create.mockResolvedValue(user);
      jwtService.signAsync
        .mockResolvedValueOnce('access-token')
        .mockResolvedValueOnce('refresh-token');
      (bcrypt.hash as jest.Mock)
        .mockResolvedValueOnce('hashed-password')
        .mockResolvedValueOnce('hashed-refresh-token');

      await expect(service.register(dto)).resolves.toEqual({
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      });

      expect(prisma.users.findUnique).toHaveBeenCalledWith({
        where: { email: dto.email },
      });
      expect(bcrypt.hash).toHaveBeenNthCalledWith(1, dto.password, 10);
      expect(prisma.users.create).toHaveBeenCalledWith({
        data: {
          name: dto.name,
          email: dto.email,
          passwordHash: 'hashed-password',
        },
      });
      expect(jwtService.signAsync).toHaveBeenNthCalledWith(
        1,
        { sub: user.id, email: user.email, role: user.role },
        { secret: 'access-secret', expiresIn: '15m' },
      );
      expect(jwtService.signAsync).toHaveBeenNthCalledWith(
        2,
        { sub: user.id, email: user.email, role: user.role },
        { secret: 'refresh-secret', expiresIn: '7d' },
      );
      expect(bcrypt.hash).toHaveBeenNthCalledWith(2, 'refresh-token', 10);
      expect(prisma.refreshToken.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          token: 'hashed-refresh-token',
          userId: user.id,
        }),
      });
      expect(
        prisma.refreshToken.create.mock.calls[0][0].data.expiresAt,
      ).toBeInstanceOf(Date);
    });

    it('throws ConflictException for a duplicate email', async () => {
      prisma.users.findUnique.mockResolvedValue(user);

      await expect(service.register(dto)).rejects.toBeInstanceOf(
        ConflictException,
      );

      expect(prisma.users.create).not.toHaveBeenCalled();
      expect(jwtService.signAsync).not.toHaveBeenCalled();
      expect(prisma.refreshToken.create).not.toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('returns the validated user and saves a rotated refresh token', async () => {
      const validatedUser = {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      };

      jwtService.signAsync
        .mockResolvedValueOnce('access-token')
        .mockResolvedValueOnce('refresh-token');
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-refresh-token');

      await expect(service.login(validatedUser)).resolves.toEqual({
        user: validatedUser,
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      });

      expect(prisma.refreshToken.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          token: 'hashed-refresh-token',
          userId: user.id,
        }),
      });
    });
  });

  describe('refreshToken', () => {
    const storedToken = {
      id: 'refresh-1',
      token: 'hashed-old-refresh-token',
      userId: user.id,
      expiresAt: new Date('2999-01-01T00:00:00.000Z'),
    };

    it('rotates a valid refresh token and returns a fresh token pair', async () => {
      prisma.refreshToken.findMany.mockResolvedValue([storedToken]);
      prisma.users.findUnique.mockResolvedValue(user);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      jwtService.signAsync
        .mockResolvedValueOnce('new-access-token')
        .mockResolvedValueOnce('new-refresh-token');
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-new-refresh-token');

      await expect(
        service.refreshToken(user.id, 'old-refresh-token'),
      ).resolves.toEqual({
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
      });

      expect(prisma.refreshToken.findMany).toHaveBeenCalledWith({
        where: { userId: user.id },
      });
      expect(bcrypt.compare).toHaveBeenCalledWith(
        'old-refresh-token',
        storedToken.token,
      );
      expect(prisma.refreshToken.delete).toHaveBeenCalledWith({
        where: { id: storedToken.id },
      });
      expect(prisma.refreshToken.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          token: 'hashed-new-refresh-token',
          userId: user.id,
        }),
      });
    });

    it('throws ForbiddenException when there are no stored refresh tokens', async () => {
      prisma.refreshToken.findMany.mockResolvedValue([]);

      await expect(
        service.refreshToken(user.id, 'refresh-token'),
      ).rejects.toBeInstanceOf(ForbiddenException);

      expect(bcrypt.compare).not.toHaveBeenCalled();
      expect(prisma.refreshToken.deleteMany).not.toHaveBeenCalled();
    });

    it('deletes all refresh tokens and throws ForbiddenException for a non-matching token', async () => {
      prisma.refreshToken.findMany.mockResolvedValue([storedToken]);
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.refreshToken(user.id, 'stolen-refresh-token'),
      ).rejects.toBeInstanceOf(ForbiddenException);

      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({
        where: { userId: user.id },
      });
      expect(prisma.refreshToken.delete).not.toHaveBeenCalled();
      expect(jwtService.signAsync).not.toHaveBeenCalled();
    });

    it('deletes the matched token and throws ForbiddenException when it is expired', async () => {
      const expiredToken = {
        ...storedToken,
        expiresAt: new Date('2000-01-01T00:00:00.000Z'),
      };

      prisma.refreshToken.findMany.mockResolvedValue([expiredToken]);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.refreshToken(user.id, 'expired-refresh-token'),
      ).rejects.toBeInstanceOf(ForbiddenException);

      expect(prisma.refreshToken.delete).toHaveBeenCalledWith({
        where: { id: expiredToken.id },
      });
      expect(jwtService.signAsync).not.toHaveBeenCalled();
    });

    it('throws NotFoundException when the refresh token is valid but the user no longer exists', async () => {
      prisma.refreshToken.findMany.mockResolvedValue([storedToken]);
      prisma.users.findUnique.mockResolvedValue(null);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.refreshToken(user.id, 'old-refresh-token'),
      ).rejects.toBeInstanceOf(NotFoundException);

      expect(prisma.refreshToken.delete).toHaveBeenCalledWith({
        where: { id: storedToken.id },
      });
      expect(prisma.refreshToken.create).not.toHaveBeenCalled();
    });
  });

  describe('me', () => {
    it('returns the current user profile', async () => {
      const profile = {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
        avatarUrl: user.avatarUrl,
      };

      prisma.users.findFirst.mockResolvedValue(profile);

      await expect(service.me(user.id)).resolves.toEqual(profile);
      expect(prisma.users.findFirst).toHaveBeenCalledWith({
        where: { id: user.id },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          createdAt: true,
          avatarUrl: true,
        },
      });
    });

    it('throws NotFoundException when the current user no longer exists', async () => {
      prisma.users.findFirst.mockResolvedValue(null);

      await expect(service.me(user.id)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('logout', () => {
    it('deletes all refresh tokens for the user', async () => {
      await expect(service.logout(user.id)).resolves.toEqual({
        message: 'Logged out successfully',
      });

      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({
        where: { userId: user.id },
      });
    });
  });
});
