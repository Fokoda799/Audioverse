// prisma/seed.ts
//
// Run with:  npx prisma db seed
// package.json must have:
//   "prisma": { "seed": "ts-node prisma/seed.ts" }

import 'dotenv/config';
import { PrismaPg }                              from '@prisma/adapter-pg';
import { PrismaClient, UserRole, ContentType }   from '@prisma/client';
import * as bcrypt                               from 'bcrypt';

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT SETUP
// ─────────────────────────────────────────────────────────────────────────────

// Fail fast — if DATABASE_URL is missing, crash immediately with a clear message
// instead of getting a confusing error deep inside Prisma
const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error('DATABASE_URL is not set in .env');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// Converts minutes → seconds — makes duration readable when writing seed data
const mins = (m: number) => m * 60;

// Deterministic placeholder images — same slug always gives same image
const cover = (seed: string) => `https://picsum.photos/seed/${seed}/400/400`;
const audio = (slug: string) => `https://cdn.audioverse.app/audio/${slug}.mp3`;

// ─────────────────────────────────────────────────────────────────────────────
// SEED DATA
// ─────────────────────────────────────────────────────────────────────────────

// ── Users ─────────────────────────────────────────────────────────────────
// Passwords are plain text here — we hash them in main() before saving.
// Never store plain text passwords in the DB, even in seed data.
const SALT_ROUNDS = 10;

const usersData = [
  {
    email:    'admin1@app.com',
    password: 'Admin@123',
    name:     'Admin User',
    role:     UserRole.ADMIN,
    profile: {
      displayName: 'Admin',
      bio:         'AudioVerse administrator',
      preferences: {
        theme:         'dark',
        playbackSpeed: 1.0,
        autoplay:      true,
        notifications: { newEpisodes: true, followers: true },
      },
    },
  },
  {
    email:    'john@app.com',
    password: 'User@123',
    name:     'John Doe',
    role:     UserRole.USER,
    profile: {
      displayName: 'John',
      bio:         'Jazz and true crime enthusiast',
      preferences: {
        theme:         'light',
        playbackSpeed: 1.5,
        autoplay:      true,
        notifications: { newEpisodes: true, followers: false },
      },
    },
  },
  {
    email:    'jane@app.com',
    password: 'User@123',
    name:     'Jane Smith',
    role:     UserRole.USER,
    profile: {
      displayName: 'Jane',
      bio:         'Podcast lover and lifelong learner',
      preferences: {
        theme:         'system',
        playbackSpeed: 1.0,
        autoplay:      false,
        notifications: { newEpisodes: true, followers: true },
      },
    },
  },
  {
    email:    'bob@app.com',
    password: 'User@123',
    name:     'Bob Johnson',
    role:     UserRole.USER,
    profile: {
      displayName: 'Bob',
      bio:         null,   // ← bio is optional — user hasn't filled it in yet
      preferences: {},     // ← empty object is valid (uses DB @default("{}"))
    },
  },
];

// ── Categories ────────────────────────────────────────────────────────────
const categoriesData = [
  { name: 'Novel',       slug: 'novel',       iconName: 'book-open',      colorHex: '#6C63FF', sortOrder: 1 },
  { name: 'Story',       slug: 'story',       iconName: 'feather',        colorHex: '#FF6584', sortOrder: 2 },
  { name: 'Motivation',  slug: 'motivation',  iconName: 'zap',            colorHex: '#F9A825', sortOrder: 3 },
  { name: 'Podcast',     slug: 'podcast',     iconName: 'mic',            colorHex: '#00BCD4', sortOrder: 4 },
  { name: 'Educational', slug: 'educational', iconName: 'graduation-cap', colorHex: '#43A047', sortOrder: 5 },
];

// ── Authors ───────────────────────────────────────────────────────────────
const authorsData = [
  {
    name:      'Sarah Mitchell',
    bio:       'Award-winning novelist with works translated into 12 languages. Known for atmospheric fiction that blurs the line between past and present.',
    avatarUrl: 'https://i.pravatar.cc/200?img=47',
  },
  {
    name:      'James Okafor',
    bio:       'Motivational speaker and bestselling author of "Rise Every Day". Has helped thousands unlock their potential through audio programs.',
    avatarUrl: 'https://i.pravatar.cc/200?img=12',
  },
  {
    name:      'Dr. Lena Hoffmann',
    bio:       'Professor of cognitive science at Berlin University. Makes complex neuroscience and psychology accessible to everyday listeners.',
    avatarUrl: 'https://i.pravatar.cc/200?img=23',
  },
  {
    name:      'Carlos Rivera',
    bio:       'Veteran podcast host and investigative journalist. Known for sharp interviews and no-nonsense commentary on culture and technology.',
    avatarUrl: 'https://i.pravatar.cc/200?img=68',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 Seeding database...\n');
  await prisma
  // ── Step 1: Clear existing data ──────────────────────────────────────────
  // Delete in reverse FK dependency order so constraints aren't violated.
  // Child tables (Favorite, ListeningHistory) must be cleared before parents.
  console.log('🗑️  Clearing existing data...');
  await prisma.favorite.deleteMany();
  await prisma.listeningHistory.deleteMany();
  await prisma.audioContent.deleteMany();
  await prisma.author.deleteMany();
  await prisma.category.deleteMany();
  await prisma.userProfile.deleteMany();
  await prisma.users.deleteMany();
  console.log('✅ Cleared\n');

  // ── Step 2: Seed Users + Profiles ────────────────────────────────────────
  // We loop instead of createMany because each user needs:
  //   1. An async bcrypt hash (can't do inside createMany)
  //   2. A nested profile create that uses the generated user.id
  console.log('👤 Seeding users...');

  for (const userData of usersData) {
    const hashedPassword = await bcrypt.hash(userData.password, SALT_ROUNDS);

    // upsert = insert if not exists, skip if exists
    // This means re-running the seed never duplicates users
    const user = await prisma.users.upsert({
      where:  { email: userData.email },
      update: {},  // ← don't overwrite anything on re-seed
      create: {
        email:        userData.email,
        name:         userData.name,
        role:         userData.role,
        passwordHash: hashedPassword,
      },
    });

    // Separate upsert for the profile — same "create only, never overwrite" pattern
    // This protects real user preferences if this seed is run against production
    await prisma.userProfile.upsert({
      where:  { userId: user.id },
      update: {},
      create: {
        userId:      user.id,
        displayName: userData.profile.displayName,
        bio:         userData.profile.bio,
        preferences: userData.profile.preferences,
      },
    });

    console.log(`   ✅ ${userData.email} (${userData.role})`);
  }

  console.log();

  // ── Step 3: Seed Categories ───────────────────────────────────────────────
  // upsert on slug so re-running never creates duplicates
  console.log('📂 Seeding categories...');

  for (const cat of categoriesData) {
    await prisma.category.upsert({
      where:  { slug: cat.slug },
      update: {},
      create: cat,
    });
  }

  // Fetch all categories back by slug so we have their generated UUIDs
  const [novel, story, motivation, podcast, educational] = await Promise.all([
    prisma.category.findUniqueOrThrow({ where: { slug: 'novel'       } }),
    prisma.category.findUniqueOrThrow({ where: { slug: 'story'       } }),
    prisma.category.findUniqueOrThrow({ where: { slug: 'motivation'  } }),
    prisma.category.findUniqueOrThrow({ where: { slug: 'podcast'     } }),
    prisma.category.findUniqueOrThrow({ where: { slug: 'educational' } }),
  ]);

  console.log('   ✅ 5 categories\n');

  // ── Step 4: Seed Authors ──────────────────────────────────────────────────
  console.log('✍️  Seeding authors...');

  for (const author of authorsData) {
    const exiting = await prisma.author.findFirst({
      where: { name: author.name }
    });

    if (exiting) continue;

    await prisma.author.create({
      data: author
    })
  }

  // Fetch authors back by name to get their UUIDs
  const [sarah, james, lena, carlos] = await Promise.all([
    prisma.author.findFirstOrThrow({ where: { name: 'Sarah Mitchell'    } }),
    prisma.author.findFirstOrThrow({ where: { name: 'James Okafor'      } }),
    prisma.author.findFirstOrThrow({ where: { name: 'Dr. Lena Hoffmann' } }),
    prisma.author.findFirstOrThrow({ where: { name: 'Carlos Rivera'     } }),
  ]);

  console.log('   ✅ 4 authors\n');

  // ── Step 5: Seed Audio Content ────────────────────────────────────────────
  // 20 items: 4 per category, each with realistic metadata
  console.log('🎧 Seeding audio content...');

  const audioContentData = [

    // ── NOVELS (4) ──────────────────────────────────────────────────────────
    {
      title: 'The Midnight Garden', slug: 'the-midnight-garden',
      description: 'A young woman discovers a hidden garden that only exists at midnight, where the past and present intertwine. A sweeping story of love, loss, and time.',
      coverUrl: cover('midnight-garden'), audioUrl: audio('the-midnight-garden'),
      durationSec: mins(487), contentType: ContentType.NOVEL,
      language: 'en', isPublished: true, playCount: 12_430,
      authorId: sarah.id, categoryId: novel.id,
    },
    {
      title: 'Echoes of the North', slug: 'echoes-of-the-north',
      description: 'Set in the frozen tundra of Iceland, a detective unravels a decades-old mystery when a glacier reveals its secrets. A gripping thriller with stunning atmosphere.',
      coverUrl: cover('echoes-north'), audioUrl: audio('echoes-of-the-north'),
      durationSec: mins(623), contentType: ContentType.NOVEL,
      language: 'en', isPublished: true, playCount: 9_872,
      authorId: sarah.id, categoryId: novel.id,
    },
    {
      title: 'The Glass Architect', slug: 'the-glass-architect',
      description: 'When a renowned architect disappears before unveiling his greatest work, his apprentice must uncover the truth hidden within the blueprints.',
      coverUrl: cover('glass-architect'), audioUrl: audio('the-glass-architect'),
      durationSec: mins(541), contentType: ContentType.NOVEL,
      language: 'en', isPublished: true, playCount: 7_215,
      authorId: sarah.id, categoryId: novel.id,
    },
    {
      title: 'Beneath Copper Skies', slug: 'beneath-copper-skies',
      description: 'A post-apocalyptic epic following three siblings across a transformed Earth where nature has reclaimed civilization.',
      coverUrl: cover('copper-skies'), audioUrl: audio('beneath-copper-skies'),
      durationSec: mins(710), contentType: ContentType.NOVEL,
      language: 'en', isPublished: false, playCount: 0,  // ← draft, not published yet
      authorId: sarah.id, categoryId: novel.id,
    },

    // ── STORIES (4) ─────────────────────────────────────────────────────────
    {
      title: "The Old Fisherman's Letter", slug: 'the-old-fishermans-letter',
      description: 'A fisherman writes one letter a year to his estranged son. Only after his death does his son read all forty-two — and understand.',
      coverUrl: cover('fisherman-letter'), audioUrl: audio('the-old-fishermans-letter'),
      durationSec: mins(42), contentType: ContentType.STORY,
      language: 'en', isPublished: true, playCount: 23_100,
      authorId: sarah.id, categoryId: story.id,
    },
    {
      title: 'Seven Minutes in Mumbai', slug: 'seven-minutes-in-mumbai',
      description: 'A chance encounter in a Mumbai train station lasts exactly seven minutes — but changes two strangers lives forever.',
      coverUrl: cover('mumbai-train'), audioUrl: audio('seven-minutes-in-mumbai'),
      durationSec: mins(35), contentType: ContentType.STORY,
      language: 'en', isPublished: true, playCount: 18_640,
      authorId: carlos.id, categoryId: story.id,
    },
    {
      title: "The Cartographer's Daughter", slug: 'the-cartographers-daughter',
      description: 'Growing up in the shadow of her famous father, a young woman sets out to map the one territory he never could — the human heart.',
      coverUrl: cover('cartographer'), audioUrl: audio('the-cartographers-daughter'),
      durationSec: mins(58), contentType: ContentType.STORY,
      language: 'en', isPublished: true, playCount: 11_290,
      authorId: sarah.id, categoryId: story.id,
    },
    {
      title: 'Last Bus to Harlem', slug: 'last-bus-to-harlem',
      description: 'On the last bus home, an unlikely friendship forms between a retired jazz musician and a teenager who has given up on music — and on herself.',
      coverUrl: cover('harlem-bus'), audioUrl: audio('last-bus-to-harlem'),
      durationSec: mins(28), contentType: ContentType.STORY,
      language: 'en', isPublished: true, playCount: 14_780,
      authorId: james.id, categoryId: story.id,
    },

    // ── MOTIVATION (4) ──────────────────────────────────────────────────────
    {
      title: 'Rise Every Day', slug: 'rise-every-day',
      description: "James Okafor's flagship program. Twelve sessions rebuilding your mindset from the ground up — covering discipline, purpose, and habits that compound.",
      coverUrl: cover('rise-every-day'), audioUrl: audio('rise-every-day'),
      durationSec: mins(180), contentType: ContentType.MOTIVATION,
      language: 'en', isPublished: true, playCount: 45_200,
      authorId: james.id, categoryId: motivation.id,
    },
    {
      title: 'The Discipline Blueprint', slug: 'the-discipline-blueprint',
      description: 'Stop relying on motivation — it runs out. Build ironclad systems that make success inevitable regardless of how you feel.',
      coverUrl: cover('discipline-blueprint'), audioUrl: audio('the-discipline-blueprint'),
      durationSec: mins(135), contentType: ContentType.MOTIVATION,
      language: 'en', isPublished: true, playCount: 31_550,
      authorId: james.id, categoryId: motivation.id,
    },
    {
      title: 'Silence the Inner Critic', slug: 'silence-the-inner-critic',
      description: 'Science-backed techniques to quiet negative self-talk and build unshakeable confidence from within.',
      coverUrl: cover('inner-critic'), audioUrl: audio('silence-the-inner-critic'),
      durationSec: mins(95), contentType: ContentType.MOTIVATION,
      language: 'en', isPublished: true, playCount: 27_830,
      authorId: james.id, categoryId: motivation.id,
    },
    {
      title: "Momentum: Start Before You're Ready", slug: 'momentum-start-before-youre-ready',
      description: 'Dismantle perfectionism and build unstoppable momentum through imperfect action. The biggest lie: you need to be ready first.',
      coverUrl: cover('momentum'), audioUrl: audio('momentum-start'),
      durationSec: mins(110), contentType: ContentType.MOTIVATION,
      language: 'en', isPublished: true, playCount: 19_400,
      authorId: james.id, categoryId: motivation.id,
    },

    // ── PODCASTS (4) ────────────────────────────────────────────────────────
    {
      title: 'Tech & Soul — Ep.42: The AI Dilemma', slug: 'tech-and-soul-ep-42',
      description: 'Carlos sits with three AI researchers to debate: Is AGI a gift or an existential risk? A balanced conversation that cuts through the hype.',
      coverUrl: cover('tech-soul-42'), audioUrl: audio('tech-and-soul-ep-42'),
      durationSec: mins(74), contentType: ContentType.PODCAST,
      language: 'en', isPublished: true, playCount: 38_910,
      authorId: carlos.id, categoryId: podcast.id,
    },
    {
      title: 'Tech & Soul — Ep.38: Designing the Future', slug: 'tech-and-soul-ep-38',
      description: 'Four world-leading product designers discuss how great design shapes human behavior — and the responsibility that power carries.',
      coverUrl: cover('tech-soul-38'), audioUrl: audio('tech-and-soul-ep-38'),
      durationSec: mins(88), contentType: ContentType.PODCAST,
      language: 'en', isPublished: true, playCount: 22_340,
      authorId: carlos.id, categoryId: podcast.id,
    },
    {
      title: 'Deep Currents: The Ocean Economy', slug: 'deep-currents-ocean-economy',
      description: 'Investigative series on how the global economy depends on — and is destroying — the world\'s oceans. Episode 1: shipping, fishing, the plastic crisis.',
      coverUrl: cover('ocean-economy'), audioUrl: audio('deep-currents-ocean'),
      durationSec: mins(62), contentType: ContentType.PODCAST,
      language: 'en', isPublished: true, playCount: 16_700,
      authorId: carlos.id, categoryId: podcast.id,
    },
    {
      title: 'Founders at Midnight: Building in Public', slug: 'founders-at-midnight',
      description: 'Founders share revenue numbers, failures, and lessons with complete transparency. No PR spin. Just real stories from the trenches.',
      coverUrl: cover('founders-midnight'), audioUrl: audio('founders-at-midnight'),
      durationSec: mins(91), contentType: ContentType.PODCAST,
      language: 'en', isPublished: true, playCount: 29_180,
      authorId: carlos.id, categoryId: podcast.id,
    },

    // ── EDUCATIONAL (4) ─────────────────────────────────────────────────────
    {
      title: 'How Memory Actually Works', slug: 'how-memory-actually-works',
      description: 'The neuroscience of memory formation, storage, and recall. Why you forget, how sleep affects learning, and evidence-based techniques to remember more.',
      coverUrl: cover('memory-science'), audioUrl: audio('how-memory-works'),
      durationSec: mins(68), contentType: ContentType.EDUCATIONAL,
      language: 'en', isPublished: true, playCount: 41_200,
      authorId: lena.id, categoryId: educational.id,
    },
    {
      title: 'The Psychology of Decision Making', slug: 'psychology-of-decision-making',
      description: 'You make thousands of decisions daily — most unconsciously. Explore cognitive biases, heuristics, and the hidden forces driving your choices.',
      coverUrl: cover('decision-making'), audioUrl: audio('psychology-decisions'),
      durationSec: mins(92), contentType: ContentType.EDUCATIONAL,
      language: 'en', isPublished: true, playCount: 33_750,
      authorId: lena.id, categoryId: educational.id,
    },
    {
      title: 'Introduction to Quantum Computing', slug: 'intro-to-quantum-computing',
      description: 'No physics degree required. Qubits, superposition, entanglement — and why quantum computers will change cryptography and medicine forever.',
      coverUrl: cover('quantum-computing'), audioUrl: audio('intro-quantum'),
      durationSec: mins(115), contentType: ContentType.EDUCATIONAL,
      language: 'en', isPublished: true, playCount: 24_600,
      authorId: lena.id, categoryId: educational.id,
    },
    {
      title: 'The History of Language', slug: 'history-of-language',
      description: 'From grunts to grammar — 150,000 years of human communication. The origins of language, how dialects form, and why languages die.',
      coverUrl: cover('history-language'), audioUrl: audio('history-language'),
      durationSec: mins(78), contentType: ContentType.EDUCATIONAL,
      language: 'en', isPublished: true, playCount: 18_900,
      authorId: lena.id, categoryId: educational.id,
    },
  ];

  // upsert on slug so re-running the seed never creates duplicate content
  for (const content of audioContentData) {
    const existing = await prisma.audioContent.findFirst({
      where: { slug: content.slug },
    });

    if (existing) continue;

    await prisma.audioContent.create({
      data: content,
    });
  }

  console.log('   ✅ 20 audio content items\n');

  // ── Summary ───────────────────────────────────────────────────────────────
  const [users, cats, authorsCount, content] = await Promise.all([
    prisma.users.count(),
    prisma.category.count(),
    prisma.author.count(),
    prisma.audioContent.count(),
  ]);

  console.log('─────────────────────────────');
  console.log('🎉 Seed complete!');
  console.log(`   👤 Users      : ${users}`);
  console.log(`   📂 Categories : ${cats}`);
  console.log(`   ✍️  Authors    : ${authorsCount}`);
  console.log(`   🎧 Content    : ${content}`);
  console.log('─────────────────────────────');
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

main()
  .catch((err) => {
    console.error('❌ Seed failed:', err);
    process.exit(1);
  })
  .finally(async () => {
    // Always disconnect — prevents the Node process from hanging after seeding
    await prisma.$disconnect();
  });
