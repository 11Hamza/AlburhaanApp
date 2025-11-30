/**
 * Database Utilities
 * PostgreSQL connection using Prisma Client
 *
 * Note: Prisma client will be generated after running `npx prisma generate`
 * For development without Prisma, we provide fallback in-memory storage
 */

// Prisma Client singleton pattern for Next.js
// Prevents creating multiple instances during hot reload

let prisma;

// Check if Prisma is available
try {
  const { PrismaClient } = require('@prisma/client');

  if (process.env.NODE_ENV === 'production') {
    prisma = new PrismaClient();
  } else {
    // In development, use a global variable to preserve the value
    // across module reloads caused by HMR (Hot Module Replacement)
    if (!global.prisma) {
      global.prisma = new PrismaClient();
    }
    prisma = global.prisma;
  }
} catch (error) {
  console.warn('Prisma Client not available. Using in-memory storage for development.');

  // In-memory fallback for development without database
  prisma = createInMemoryDb();
}

/**
 * Create in-memory database for development
 * This allows the app to run without PostgreSQL for testing
 */
function createInMemoryDb() {
  const store = {
    sessions: [],
    userPreferences: [],
    favorites: [],
    recentlyViewed: [],
    pushTokens: [],
    filterCache: [],
  };

  return {
    session: {
      create: async ({ data }) => {
        const id = crypto.randomUUID();
        const record = { id, ...data, createdAt: new Date() };
        store.sessions.push(record);
        return record;
      },
      findUnique: async ({ where }) => {
        return store.sessions.find(s => s.token === where.token) || null;
      },
      delete: async ({ where }) => {
        const index = store.sessions.findIndex(s => s.token === where.token);
        if (index > -1) {
          return store.sessions.splice(index, 1)[0];
        }
        return null;
      },
      deleteMany: async ({ where }) => {
        const before = store.sessions.length;
        store.sessions = store.sessions.filter(s => s.patronId !== where.patronId);
        return { count: before - store.sessions.length };
      },
    },

    userPreference: {
      upsert: async ({ where, update, create }) => {
        const existing = store.userPreferences.find(p => p.patronId === where.patronId);
        if (existing) {
          Object.assign(existing, update, { updatedAt: new Date() });
          return existing;
        }
        const id = crypto.randomUUID();
        const record = { id, ...create, createdAt: new Date(), updatedAt: new Date() };
        store.userPreferences.push(record);
        return record;
      },
      findUnique: async ({ where }) => {
        return store.userPreferences.find(p => p.patronId === where.patronId) || null;
      },
    },

    favorite: {
      create: async ({ data }) => {
        const existing = store.favorites.find(
          f => f.patronId === data.patronId && f.biblioId === data.biblioId
        );
        if (existing) return existing;
        const id = crypto.randomUUID();
        const record = { id, ...data, createdAt: new Date() };
        store.favorites.push(record);
        return record;
      },
      findMany: async ({ where, orderBy }) => {
        let results = store.favorites.filter(f => f.patronId === where.patronId);
        if (orderBy?.createdAt === 'desc') {
          results.sort((a, b) => b.createdAt - a.createdAt);
        }
        return results;
      },
      delete: async ({ where }) => {
        const index = store.favorites.findIndex(
          f => f.patronId === where.patronId_biblioId.patronId &&
               f.biblioId === where.patronId_biblioId.biblioId
        );
        if (index > -1) {
          return store.favorites.splice(index, 1)[0];
        }
        return null;
      },
      findUnique: async ({ where }) => {
        return store.favorites.find(
          f => f.patronId === where.patronId_biblioId.patronId &&
               f.biblioId === where.patronId_biblioId.biblioId
        ) || null;
      },
    },

    recentlyViewed: {
      upsert: async ({ where, update, create }) => {
        const existing = store.recentlyViewed.find(
          r => r.patronId === where.patronId_biblioId.patronId &&
               r.biblioId === where.patronId_biblioId.biblioId
        );
        if (existing) {
          Object.assign(existing, update);
          return existing;
        }
        const id = crypto.randomUUID();
        const record = { id, ...create };
        store.recentlyViewed.push(record);
        return record;
      },
      findMany: async ({ where, orderBy, take }) => {
        let results = store.recentlyViewed.filter(r => r.patronId === where.patronId);
        if (orderBy?.viewedAt === 'desc') {
          results.sort((a, b) => b.viewedAt - a.viewedAt);
        }
        if (take) {
          results = results.slice(0, take);
        }
        return results;
      },
    },

    filterCache: {
      findMany: async ({ where }) => {
        return store.filterCache.filter(f => f.filterType === where.filterType);
      },
      upsert: async ({ where, update, create }) => {
        const existing = store.filterCache.find(
          f => f.filterType === where.filterType_value.filterType &&
               f.value === where.filterType_value.value
        );
        if (existing) {
          Object.assign(existing, update, { updatedAt: new Date() });
          return existing;
        }
        const id = crypto.randomUUID();
        const record = { id, ...create, updatedAt: new Date() };
        store.filterCache.push(record);
        return record;
      },
    },

    // For raw queries
    $queryRaw: async () => [],
    $executeRaw: async () => 0,
  };
}

module.exports = { prisma };
