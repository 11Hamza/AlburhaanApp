/**
 * Cache Warmer
 * Pre-loads all caches at startup and schedules daily refresh at midnight
 */

import { getBooks, getLibraries } from './koha.js';
import { formatBookResponse, formatLibraryResponse } from './helpers.js';
import cache, { CACHE_TTL } from './cache.js';

let isWarming = false;

/**
 * Extract YouTube video ID from URL
 */
function extractYouTubeId(url) {
  if (!url) return null;
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)/,
    /youtube\.com\/v\/([^&\n?#]+)/,
  ];
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) return match[1];
  }
  return null;
}

/**
 * Warm all caches - fetches all data from Koha once
 */
export async function warmAllCaches() {
  if (isWarming) {
    console.log('Cache warming already in progress...');
    return;
  }

  isWarming = true;
  console.log('🔥 Starting cache warm-up...');
  const startTime = Date.now();

  try {
    // 1. Fetch ALL books from Koha (this is the slow part - do it ONCE)
    console.log('  📚 Fetching all books from Koha...');
    const allBooks = [];
    let page = 1;
    let hasMore = true;
    const maxPages = 60;

    while (hasMore && page <= maxPages) {
      const result = await getBooks({ page, perPage: 100 });

      if (result.success && Array.isArray(result.data) && result.data.length > 0) {
        const formattedBooks = result.data.map(formatBookResponse);
        allBooks.push(...formattedBooks);

        if (result.data.length < 100) {
          hasMore = false;
        } else {
          page++;
        }

        // Log progress every 10 pages
        if (page % 10 === 0) {
          console.log(`    ... fetched ${allBooks.length} books (page ${page})`);
        }
      } else {
        hasMore = false;
      }
    }

    console.log(`  ✅ Fetched ${allBooks.length} total books`);

    // 2. Cache book pages (first 10 pages)
    console.log('  📖 Caching book listing pages...');
    for (let p = 1; p <= 10; p++) {
      const startIdx = (p - 1) * 10;
      const pageBooks = allBooks.slice(startIdx, startIdx + 10);
      const cacheKey = cache.key('books', { page: p, perPage: 10, query: null });
      cache.set(cacheKey, {
        success: true,
        data: pageBooks,
        pagination: {
          page: p,
          perPage: 10,
          total: allBooks.length,
          totalPages: Math.ceil(allBooks.length / 10),
          hasMore: p * 10 < allBooks.length,
        },
      }, CACHE_TTL.BOOKS_LIST);
    }

    // 3. Extract and cache videos (books with YouTube URLs)
    console.log('  🎬 Caching videos...');
    const videos = allBooks
      .filter(book => book.youtubeUrl)
      .map(book => {
        const youtubeId = extractYouTubeId(book.youtubeUrl);
        return {
          id: `koha-${book.biblioId}`,
          youtubeId,
          title: book.title,
          description: null,
          category: 'Library',
          thumbnailUrl: youtubeId ? `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg` : null,
          duration: null,
          speaker: book.author,
          language: book.language || 'en',
          publishedAt: null,
          createdAt: new Date().toISOString(),
          biblioId: book.biblioId,
          youtubeUrl: book.youtubeUrl,
        };
      });

    cache.set('videos:all', videos, CACHE_TTL.BOOKS_LIST);
    console.log(`  ✅ Cached ${videos.length} videos`);

    // 4. Extract and cache ebooks (books with PDF/ebook URLs)
    console.log('  📱 Caching ebooks...');
    const ebooks = allBooks
      .filter(book => book.ebookUrl || book.pdfUrl)
      .map(book => ({
        id: `koha-${book.biblioId}`,
        title: book.title,
        author: book.author,
        description: null,
        category: 'Library',
        coverUrl: book.imageUrl,
        accessUrl: book.pdfUrl || book.ebookUrl,
        fileType: book.pdfUrl ? 'pdf' : 'ebook',
        language: book.language || 'en',
        createdAt: new Date().toISOString(),
        biblioId: book.biblioId,
      }));

    cache.set('ebooks:all', ebooks, CACHE_TTL.BOOKS_LIST);
    console.log(`  ✅ Cached ${ebooks.length} ebooks`);

    // 5. Cache libraries
    console.log('  🏛️ Caching libraries...');
    const librariesResult = await getLibraries();
    if (librariesResult.success) {
      const libraries = Array.isArray(librariesResult.data)
        ? librariesResult.data.map(formatLibraryResponse)
        : [];
      libraries.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
      cache.set('libraries:all', { libraries, total: libraries.length }, CACHE_TTL.LIBRARIES);
      console.log(`  ✅ Cached ${libraries.length} libraries`);
    }

    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`🔥 Cache warm-up complete! (${duration}s)`);
    console.log(`   - ${allBooks.length} books`);
    console.log(`   - ${videos.length} videos`);
    console.log(`   - ${ebooks.length} ebooks`);

  } catch (error) {
    console.error('Cache warm-up error:', error);
  } finally {
    isWarming = false;
  }
}

/**
 * Schedule daily cache refresh at midnight
 */
export function scheduleDailyRefresh() {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(24, 0, 0, 0); // Next midnight

  const msUntilMidnight = midnight.getTime() - now.getTime();

  console.log(`⏰ Next cache refresh scheduled for midnight (in ${Math.round(msUntilMidnight / 1000 / 60)} minutes)`);

  // First refresh at midnight
  setTimeout(() => {
    console.log('⏰ Midnight refresh triggered');
    warmAllCaches();

    // Then refresh every 24 hours
    setInterval(() => {
      console.log('⏰ Daily refresh triggered');
      warmAllCaches();
    }, 24 * 60 * 60 * 1000);

  }, msUntilMidnight);
}

/**
 * Initialize cache warming (call on server start)
 */
export async function initializeCacheWarming() {
  console.log('');
  console.log('='.repeat(50));
  console.log('  CACHE WARMING INITIALIZATION');
  console.log('='.repeat(50));

  // Warm caches immediately on startup
  await warmAllCaches();

  // Schedule daily refresh at midnight
  scheduleDailyRefresh();

  console.log('='.repeat(50));
  console.log('');
}
