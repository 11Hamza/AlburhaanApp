/**
 * GET /api/books
 * List all books with pagination and optional filters
 *
 * Query params:
 * - page: Page number (default: 1)
 * - per_page: Items per page (default: 10, max: 100)
 * - q: Search query (searches title)
 * - author: Filter by author
 * - subject: Filter by subject (650 field)
 * - language: Filter by language
 * - library: Filter by library branch
 */

import { getBooks } from '@/lib/koha';
import { formatBookResponse, getPaginationParams, paginatedResponse } from '@/lib/helpers';
import { errorResponse } from '@/lib/auth';

// Cached total book count (shared with /api/books/count)
let cachedTotalBooks = 5177; // Default from count-books.js analysis
let lastCountFetch = null;
const COUNT_CACHE_DURATION = 60 * 60 * 1000; // 1 hour

// Background refresh of total count
async function refreshTotalCount() {
  if (lastCountFetch && (Date.now() - lastCountFetch < COUNT_CACHE_DURATION)) {
    return;
  }

  try {
    console.log('Background: Refreshing total book count...');
    let total = 0;
    let page = 1;
    let hasMore = true;

    while (hasMore && page <= 100) {
      const result = await getBooks({ page, perPage: 100 });
      if (result.success && Array.isArray(result.data) && result.data.length > 0) {
        total += result.data.length;
        hasMore = result.data.length === 100;
        page++;
      } else {
        hasMore = false;
      }
    }

    cachedTotalBooks = total;
    lastCountFetch = Date.now();
    console.log('Background: Total book count updated to', total);
  } catch (error) {
    console.error('Background count refresh failed:', error);
  }
}

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);

    // Get filter parameters
    const query = searchParams.get('q') || null;
    const author = searchParams.get('author') || null;
    const subject = searchParams.get('subject') || null;
    const language = searchParams.get('language') || null;
    const library = searchParams.get('library') || null;

    // Build filters object
    const filters = {};
    if (author) filters.author = author;
    if (subject) filters.subject = subject;
    if (language) filters.language = language;
    if (library) filters.library = library;

    // Fetch books from Koha
    const result = await getBooks({
      page,
      perPage,
      query,
      filters,
    });

    console.log('Books API result:', JSON.stringify(result, null, 2).substring(0, 500));

    if (!result.success) {
      console.error('Books fetch failed:', result.error, result.status);
      return errorResponse(result.error || 'Failed to fetch books', result.status || 500);
    }

    // Format book responses
    const books = Array.isArray(result.data)
      ? result.data.map(formatBookResponse)
      : [];

    // Use total from Koha X-Total-Count header, or fall back to cached total
    // For filtered queries, use the page-based hasMore logic
    const hasFilters = query || Object.keys(filters).length > 0;
    const total = result.total || (hasFilters ? null : cachedTotalBooks);

    // Trigger background refresh of total count (non-blocking)
    if (!hasFilters) {
      refreshTotalCount().catch(() => {});
    }

    return Response.json(paginatedResponse(books, page, perPage, total));

  } catch (error) {
    console.error('Books listing error:', error);
    return errorResponse('Internal server error', 500);
  }
}
