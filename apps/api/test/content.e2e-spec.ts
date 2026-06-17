// test/content.e2e-spec.ts
//
// Full integration tests for the Content endpoints.
// These tests spin up the REAL NestJS app and hit REAL HTTP endpoints —
// they test the full stack: controller → service → Prisma → test database.

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaClient, UserRole, ContentType } from '@prisma/client';

import { AppModule }         from '../src/app.module';
import { cleanDatabase }     from './helpers/db-cleanup.helper';
import { createTestUser }    from './helpers/auth.helper';

describe('Content (e2e)', () => {
  let app:    INestApplication;
  let prisma: PrismaClient;

  // Shared test data — created once before all tests run
  let adminToken:  string;
  let userToken:   string;
  let categoryId:  string;
  let authorId:    string;

  // ── Runs once before ALL tests in this file ────────────────────────────────
  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();

    // Apply the same global pipes your real main.ts uses —
    // otherwise validation behavior in tests won't match production
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

    await app.init();

    prisma = new PrismaClient();
    await cleanDatabase(prisma);

    // Create one admin and one regular user to reuse across all tests
    const admin = await createTestUser(app, prisma, UserRole.ADMIN);
    const user  = await createTestUser(app, prisma, UserRole.USER);
    adminToken  = admin.accessToken;
    userToken   = user.accessToken;

    // Create a category and author to attach content to
    const category = await prisma.category.create({
      data: { name: 'Novel', slug: 'novel', sortOrder: 1 },
    });
    categoryId = category.id;

    const author = await prisma.author.create({
      data: { name: 'Test Author', bio: 'A bio for testing purposes' },
    });
    authorId = author.id;
  });

  // ── Runs once after ALL tests finish ───────────────────────────────────────
  afterAll(async () => {
    await cleanDatabase(prisma);
    await prisma.$disconnect();
    await app.close();
  });

  // ── Clears only AudioContent between individual tests ─────────────────────
  // Keeps the shared category/author/users but resets content state,
  // so tests don't interfere with each other (e.g. one test's "delete"
  // shouldn't affect another test's "findAll" count).
  afterEach(async () => {
    await prisma.audioContent.deleteMany();
  });

  // ── Helper to create a content record directly via Prisma ─────────────────
  // Used in tests that need EXISTING content to test against
  // (e.g. testing GET /:id, PATCH, DELETE)
  async function createTestContent(overrides: Partial<{
    title: string; slug: string; isPublished: boolean;
  }> = {}) {
    return prisma.audioContent.create({
      data: {
        title:       overrides.title ?? 'Test Book',
        slug:        overrides.slug  ?? `test-book-${Date.now()}`,
        description: 'A test description that is long enough to pass validation',
        coverUrl:    'audioverse/covers/test-cover',
        audioUrl:    'audioverse/audio/test-audio',
        durationSec: 1800,
        contentType: ContentType.NOVEL,
        language:    'en',
        isPublished: overrides.isPublished ?? true,
        playCount:   0,
        authorId,
        categoryId,
      },
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GET /content
  // ═══════════════════════════════════════════════════════════════════════
  describe('GET /content', () => {
    it('returns an empty list when no content exists', async () => {
      const res = await request(app.getHttpServer())
        .get('/content')
        .expect(200);

      expect(res.body.items).toEqual([]);
      expect(res.body.meta.total).toBe(0);
    });

    it('returns published content with pagination metadata', async () => {
      await createTestContent({ slug: 'book-1' });
      await createTestContent({ slug: 'book-2' });

      const res = await request(app.getHttpServer())
        .get('/content')
        .expect(200);

      expect(res.body.items).toHaveLength(2);
      expect(res.body.meta).toMatchObject({
        total: 2,
        page:  1,
        limit: 10,
      });
    });

    it('filters results by categoryId', async () => {
      await createTestContent({ slug: 'matching-book' });

      const otherCategory = await prisma.category.create({
        data: { name: 'Podcast', slug: 'podcast-test', sortOrder: 2 },
      });

      await prisma.audioContent.create({
        data: {
          title: 'Other Category Book', slug: 'other-book',
          description: 'Belongs to a different category for filter testing',
          coverUrl: 'x', audioUrl: 'x', durationSec: 100,
          contentType: ContentType.PODCAST, isPublished: true, playCount: 0,
          authorId, categoryId: otherCategory.id,
        },
      });

      const res = await request(app.getHttpServer())
        .get('/content')
        .query({ categoryId })
        .expect(200);

      expect(res.body.items).toHaveLength(1);
      expect(res.body.items[0].slug).toBe('matching-book');
    });

    it('respects pagination — page and limit', async () => {
      // Create 15 items to test pagination across pages
      await Promise.all(
        Array.from({ length: 15 }).map((_, i) =>
          createTestContent({ slug: `paginated-book-${i}` }),
        ),
      );

      const res = await request(app.getHttpServer())
        .get('/content')
        .query({ page: 2, limit: 10 })
        .expect(200);

      expect(res.body.items).toHaveLength(5); // remaining 5 items on page 2
      expect(res.body.meta.page).toBe(2);
      expect(res.body.meta.hasNextPage).toBe(false);
      expect(res.body.meta.hasPrevPage).toBe(true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // GET /content/:id
  // ═══════════════════════════════════════════════════════════════════════
  describe('GET /content/:id', () => {
    it('returns the content with author and category details', async () => {
      const content = await createTestContent();

      const res = await request(app.getHttpServer())
        .get(`/content/${content.id}`)
        .expect(200);

      expect(res.body.id).toBe(content.id);
      expect(res.body.author).toBeDefined();
      expect(res.body.category).toBeDefined();
    });

    it('returns 404 for a non-existent id', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';

      await request(app.getHttpServer())
        .get(`/content/${fakeId}`)
        .expect(404);
    });

    it('returns 400 for an invalid UUID format', async () => {
      await request(app.getHttpServer())
        .get('/content/not-a-uuid')
        .expect(400);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // POST /content
  // ═══════════════════════════════════════════════════════════════════════
  describe('POST /content', () => {
    const validPayload = () => ({
      title:       'New Audio Book',
      slug:        `new-audio-book-${Date.now()}`,
      description: 'A sufficiently long description for validation purposes',
      coverUrl:    'audioverse/covers/abc',
      audioUrl:    'audioverse/audio/xyz',
      durationSec: 3600,
      contentType: 'NOVEL',
      language:    'en',
      isPublished: true,
      authorId,
      categoryId,
    });

    it('creates content when called by an admin', async () => {
      const res = await request(app.getHttpServer())
        .post('/content')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(validPayload())
        .expect(201);

      expect(res.body.id).toBeDefined();
      expect(res.body.playCount).toBe(0); // always starts at 0

      // Confirm it actually landed in the database
      const inDb = await prisma.audioContent.findUnique({
        where: { id: res.body.id },
      });
      expect(inDb).not.toBeNull();
    });

    it('rejects the request when called by a regular user', async () => {
      await request(app.getHttpServer())
        .post('/content')
        .set('Authorization', `Bearer ${userToken}`)
        .send(validPayload())
        .expect(403); // RolesGuard blocks non-admins
    });

    it('rejects the request when no token is provided', async () => {
      await request(app.getHttpServer())
        .post('/content')
        .send(validPayload())
        .expect(401);
    });

    it('rejects a duplicate slug with 409 Conflict', async () => {
      const payload = validPayload();
      await createTestContent({ slug: payload.slug });

      await request(app.getHttpServer())
        .post('/content')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(payload)
        .expect(409);
    });

    it('rejects an invalid payload with 400', async () => {
      const invalidPayload = {
        title: 'A', // too short — fails @MinLength(2)... actually passes, use empty
        slug:  '',
      };

      await request(app.getHttpServer())
        .post('/content')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(invalidPayload)
        .expect(400);
    });

    it('rejects an unknown contentType enum value', async () => {
      const payload = { ...validPayload(), contentType: 'NOT_A_REAL_TYPE' };

      await request(app.getHttpServer())
        .post('/content')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(payload)
        .expect(400);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // PATCH /content/:id
  // ═══════════════════════════════════════════════════════════════════════
  describe('PATCH /content/:id', () => {
    it('updates only the provided fields when called by an admin', async () => {
      const content = await createTestContent();

      const res = await request(app.getHttpServer())
        .patch(`/content/${content.id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ title: 'Updated Title' })
        .expect(200);

      expect(res.body.title).toBe('Updated Title');
      // Unchanged fields should remain the same
      expect(res.body.description).toBe(content.description);
    });

    it('rejects the request when called by a regular user', async () => {
      const content = await createTestContent();

      await request(app.getHttpServer())
        .patch(`/content/${content.id}`)
        .set('Authorization', `Bearer ${userToken}`)
        .send({ title: 'Hacked Title' })
        .expect(403);
    });

    it('returns 404 when updating a non-existent content item', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';

      await request(app.getHttpServer())
        .patch(`/content/${fakeId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ title: 'Doesnt Matter' })
        .expect(404);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // DELETE /content/:id
  // ═══════════════════════════════════════════════════════════════════════
  describe('DELETE /content/:id', () => {
    it('deletes the content when called by an admin', async () => {
      const content = await createTestContent();

      await request(app.getHttpServer())
        .delete(`/content/${content.id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const inDb = await prisma.audioContent.findUnique({
        where: { id: content.id },
      });
      expect(inDb).toBeNull(); // confirms it's actually gone
    });

    it('rejects the request when called by a regular user', async () => {
      const content = await createTestContent();

      await request(app.getHttpServer())
        .delete(`/content/${content.id}`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(403);
    });

    it('returns 404 when deleting a non-existent content item', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';

      await request(app.getHttpServer())
        .delete(`/content/${fakeId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // POST /content/:id/play
  // ═══════════════════════════════════════════════════════════════════════
  describe('POST /content/:id/play', () => {
    it('increments the play count for an authenticated user', async () => {
      const content = await createTestContent();

      const res = await request(app.getHttpServer())
        .post(`/content/${content.id}/play`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(res.body.playCount).toBe(1);

      // Call it again to confirm it keeps incrementing, not resetting
      const res2 = await request(app.getHttpServer())
        .post(`/content/${content.id}/play`)
        .set('Authorization', `Bearer ${userToken}`)
        .expect(200);

      expect(res2.body.playCount).toBe(2);
    });

    it('rejects the request when no token is provided', async () => {
      const content = await createTestContent();

      await request(app.getHttpServer())
        .post(`/content/${content.id}/play`)
        .expect(401);
    });
  });
});