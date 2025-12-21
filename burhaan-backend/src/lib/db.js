/**
 * Database Utilities
 * PostgreSQL connection using Prisma Client
 *
 * Note: Prisma client will be generated after running `npx prisma generate`
 * For development without Prisma, we provide fallback in-memory storage
 */

// Prisma Client singleton pattern for Next.js
// Prevents creating multiple instances during hot reload

let prismaClient;

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
    readingLists: [],
    readingListItems: [],
    ebooks: [],
    youtubeVideos: [],
    ssoAccounts: [],
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

    // SSO Accounts - Link external OAuth accounts to Koha patrons
    ssoAccount: {
      create: async ({ data }) => {
        const id = crypto.randomUUID();
        const record = { id, ...data, createdAt: new Date(), updatedAt: new Date() };
        store.ssoAccounts.push(record);
        return record;
      },
      findUnique: async ({ where }) => {
        if (where.provider_providerAccountId) {
          return store.ssoAccounts.find(
            s => s.provider === where.provider_providerAccountId.provider &&
                 s.providerAccountId === where.provider_providerAccountId.providerAccountId
          ) || null;
        }
        return store.ssoAccounts.find(s => s.id === where.id) || null;
      },
      findFirst: async ({ where }) => {
        if (where.email && where.provider) {
          return store.ssoAccounts.find(
            s => s.email === where.email && s.provider === where.provider
          ) || null;
        }
        if (where.patronId) {
          return store.ssoAccounts.find(s => s.patronId === where.patronId) || null;
        }
        return null;
      },
      findMany: async ({ where }) => {
        if (where.patronId) {
          return store.ssoAccounts.filter(s => s.patronId === where.patronId);
        }
        return [];
      },
      update: async ({ where, data }) => {
        const account = store.ssoAccounts.find(s => s.id === where.id);
        if (account) {
          Object.assign(account, data, { updatedAt: new Date() });
          return account;
        }
        return null;
      },
      delete: async ({ where }) => {
        const index = store.ssoAccounts.findIndex(s => s.id === where.id);
        if (index > -1) {
          return store.ssoAccounts.splice(index, 1)[0];
        }
        return null;
      },
    },

    // Reading Lists
    readingList: {
      create: async ({ data }) => {
        const id = crypto.randomUUID();
        const record = {
          id,
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
          itemCount: 0,
        };
        store.readingLists.push(record);
        return record;
      },
      findMany: async ({ where, orderBy }) => {
        let results = store.readingLists.filter(r => r.patronId === where.patronId);
        if (orderBy?.updatedAt === 'desc') {
          results.sort((a, b) => b.updatedAt - a.updatedAt);
        }
        if (orderBy?.createdAt === 'desc') {
          results.sort((a, b) => b.createdAt - a.createdAt);
        }
        return results;
      },
      findUnique: async ({ where }) => {
        return store.readingLists.find(r => r.id === where.id) || null;
      },
      update: async ({ where, data }) => {
        const list = store.readingLists.find(r => r.id === where.id);
        if (list) {
          Object.assign(list, data, { updatedAt: new Date() });
          return list;
        }
        return null;
      },
      delete: async ({ where }) => {
        const index = store.readingLists.findIndex(r => r.id === where.id);
        if (index > -1) {
          // Also delete all items in this list
          store.readingListItems = store.readingListItems.filter(
            item => item.listId !== where.id
          );
          return store.readingLists.splice(index, 1)[0];
        }
        return null;
      },
    },

    // Reading List Items
    readingListItem: {
      create: async ({ data }) => {
        const existing = store.readingListItems.find(
          i => i.listId === data.listId && i.biblioId === data.biblioId
        );
        if (existing) return existing;

        const id = crypto.randomUUID();
        const record = { id, ...data, addedAt: new Date() };
        store.readingListItems.push(record);

        // Update item count on the list
        const list = store.readingLists.find(l => l.id === data.listId);
        if (list) {
          list.itemCount = store.readingListItems.filter(i => i.listId === data.listId).length;
          list.updatedAt = new Date();
        }

        return record;
      },
      findMany: async ({ where, orderBy }) => {
        let results = store.readingListItems.filter(i => i.listId === where.listId);
        if (orderBy?.addedAt === 'desc') {
          results.sort((a, b) => b.addedAt - a.addedAt);
        }
        return results;
      },
      findUnique: async ({ where }) => {
        if (where.listId_biblioId) {
          return store.readingListItems.find(
            i => i.listId === where.listId_biblioId.listId &&
                 i.biblioId === where.listId_biblioId.biblioId
          ) || null;
        }
        return store.readingListItems.find(i => i.id === where.id) || null;
      },
      delete: async ({ where }) => {
        let index = -1;
        if (where.listId_biblioId) {
          index = store.readingListItems.findIndex(
            i => i.listId === where.listId_biblioId.listId &&
                 i.biblioId === where.listId_biblioId.biblioId
          );
        } else {
          index = store.readingListItems.findIndex(i => i.id === where.id);
        }

        if (index > -1) {
          const deleted = store.readingListItems.splice(index, 1)[0];

          // Update item count on the list
          const list = store.readingLists.find(l => l.id === deleted.listId);
          if (list) {
            list.itemCount = store.readingListItems.filter(i => i.listId === deleted.listId).length;
            list.updatedAt = new Date();
          }

          return deleted;
        }
        return null;
      },
    },

    // eBooks
    ebook: {
      create: async ({ data }) => {
        const id = crypto.randomUUID();
        const record = { id, ...data, createdAt: new Date(), updatedAt: new Date() };
        store.ebooks.push(record);
        return record;
      },
      findMany: async ({ where, orderBy, skip, take }) => {
        let results = [...store.ebooks];

        if (where?.category) {
          results = results.filter(e => e.category === where.category);
        }
        if (where?.isActive !== undefined) {
          results = results.filter(e => e.isActive === where.isActive);
        }

        if (orderBy?.createdAt === 'desc') {
          results.sort((a, b) => b.createdAt - a.createdAt);
        }
        if (orderBy?.title === 'asc') {
          results.sort((a, b) => a.title.localeCompare(b.title));
        }

        if (skip) results = results.slice(skip);
        if (take) results = results.slice(0, take);

        return results;
      },
      findUnique: async ({ where }) => {
        return store.ebooks.find(e => e.id === where.id) || null;
      },
      update: async ({ where, data }) => {
        const ebook = store.ebooks.find(e => e.id === where.id);
        if (ebook) {
          Object.assign(ebook, data, { updatedAt: new Date() });
          return ebook;
        }
        return null;
      },
      delete: async ({ where }) => {
        const index = store.ebooks.findIndex(e => e.id === where.id);
        if (index > -1) {
          return store.ebooks.splice(index, 1)[0];
        }
        return null;
      },
      count: async ({ where }) => {
        let results = [...store.ebooks];
        if (where?.category) {
          results = results.filter(e => e.category === where.category);
        }
        if (where?.isActive !== undefined) {
          results = results.filter(e => e.isActive === where.isActive);
        }
        return results.length;
      },
    },

    // YouTube Videos
    youtubeVideo: {
      create: async ({ data }) => {
        const id = crypto.randomUUID();
        const record = { id, ...data, createdAt: new Date(), updatedAt: new Date() };
        store.youtubeVideos.push(record);
        return record;
      },
      findMany: async ({ where, orderBy, skip, take }) => {
        let results = [...store.youtubeVideos];

        if (where?.category) {
          results = results.filter(v => v.category === where.category);
        }
        if (where?.isActive !== undefined) {
          results = results.filter(v => v.isActive === where.isActive);
        }

        if (orderBy?.createdAt === 'desc') {
          results.sort((a, b) => b.createdAt - a.createdAt);
        }
        if (orderBy?.title === 'asc') {
          results.sort((a, b) => a.title.localeCompare(b.title));
        }

        if (skip) results = results.slice(skip);
        if (take) results = results.slice(0, take);

        return results;
      },
      findUnique: async ({ where }) => {
        if (where.youtubeId) {
          return store.youtubeVideos.find(v => v.youtubeId === where.youtubeId) || null;
        }
        return store.youtubeVideos.find(v => v.id === where.id) || null;
      },
      update: async ({ where, data }) => {
        const video = store.youtubeVideos.find(v => v.id === where.id);
        if (video) {
          Object.assign(video, data, { updatedAt: new Date() });
          return video;
        }
        return null;
      },
      delete: async ({ where }) => {
        const index = store.youtubeVideos.findIndex(v => v.id === where.id);
        if (index > -1) {
          return store.youtubeVideos.splice(index, 1)[0];
        }
        return null;
      },
      count: async ({ where }) => {
        let results = [...store.youtubeVideos];
        if (where?.category) {
          results = results.filter(v => v.category === where.category);
        }
        if (where?.isActive !== undefined) {
          results = results.filter(v => v.isActive === where.isActive);
        }
        return results.length;
      },
    },

    // Push Tokens
    pushToken: {
      upsert: async ({ where, update, create }) => {
        const existing = store.pushTokens.find(
          p => p.patronId === where.patronId_deviceId?.patronId &&
               p.deviceId === where.patronId_deviceId?.deviceId
        );
        if (existing) {
          Object.assign(existing, update, { updatedAt: new Date() });
          return existing;
        }
        const id = crypto.randomUUID();
        const record = { id, ...create, createdAt: new Date(), updatedAt: new Date() };
        store.pushTokens.push(record);
        return record;
      },
      findMany: async ({ where }) => {
        if (where.patronId) {
          return store.pushTokens.filter(p => p.patronId === where.patronId);
        }
        return store.pushTokens;
      },
      delete: async ({ where }) => {
        const index = store.pushTokens.findIndex(
          p => p.patronId === where.patronId_deviceId?.patronId &&
               p.deviceId === where.patronId_deviceId?.deviceId
        );
        if (index > -1) {
          return store.pushTokens.splice(index, 1)[0];
        }
        return null;
      },
    },

    // For raw queries
    $queryRaw: async () => [],
    $executeRaw: async () => 0,
  };
}

// Initialize prisma client
try {
  // Dynamic import for Prisma
  const loadPrisma = async () => {
    try {
      const { PrismaClient } = await import('@prisma/client');
      if (process.env.NODE_ENV === 'production') {
        return new PrismaClient();
      } else {
        if (!global.prisma) {
          global.prisma = new PrismaClient();
        }
        return global.prisma;
      }
    } catch {
      console.warn('Prisma Client not available. Using in-memory storage for development.');
      return createInMemoryDb();
    }
  };

  // For now, use in-memory as default
  prismaClient = createInMemoryDb();
} catch (error) {
  console.warn('Prisma Client not available. Using in-memory storage for development.');
  prismaClient = createInMemoryDb();
}

export const prisma = prismaClient;
