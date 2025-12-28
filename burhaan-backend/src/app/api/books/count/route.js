/**
 * GET /api/books/count
 * Get total book count from Koha (cached for 1 hour)
 *
 * This endpoint fetches all pages to count total books since Koha
 * doesn't provide X-Total-Count header reliably.
 */

import { getBooks } from '@/lib/koha';

// Cache for total book count
let cachedCount = null;
let cacheTime = null;
const CACHE_DURATION = 60 * 60 * 1000; // 1 hour

export async function GET(request) {
  try {
    // Check cache
    if (cachedCount !== null && cacheTime && (Date.now() - cacheTime < CACHE_DURATION)) {
      console.log('Returning cached book count:', cachedCount);
      return Response.json({
        success: true,
        total: cachedCount,
        cached: true,
        cacheAge: Math.floor((Date.now() - cacheTime) / 1000),
      });
    }

    console.log('Fetching total book count from Koha...');

    // Fetch all pages to count total books
    let totalBooks = 0;
    let page = 1;
    let hasMore = true;
    const perPage = 100;
    const maxPages = 100; // Safety limit

    while (hasMore && page <= maxPages) {
      const result = await getBooks({ page, perPage });

      if (result.success && Array.isArray(result.data)) {
        totalBooks += result.data.length;
        console.log(`  Page ${page}: ${result.data.length} books (total: ${totalBooks})`);

        if (result.data.length < perPage) {
          hasMore = false;
        } else {
          page++;
        }
      } else {
        console.error('Error fetching books for count:', result.error);
        hasMore = false;
      }
    }

    // Update cache
    cachedCount = totalBooks;
    cacheTime = Date.now();

    console.log('Total books counted:', totalBooks);

    return Response.json({
      success: true,
      total: totalBooks,
      cached: false,
    });

  } catch (error) {
    console.error('Book count error:', error);

    // Return cached count if available, even if expired
    if (cachedCount !== null) {
      return Response.json({
        success: true,
        total: cachedCount,
        cached: true,
        stale: true,
      });
    }

    return Response.json(
      { success: false, error: 'Failed to count books' },
      { status: 500 }
    );
  }
}
