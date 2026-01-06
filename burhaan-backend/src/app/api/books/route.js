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
import cache, { CACHE_TTL } from '@/lib/cache';

// Hardcoded total - avoids expensive loop through all 5000+ books
// Update this value periodically when books are added to catalog
const TOTAL_BOOKS = 5177;

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

    // Generate cache key based on all parameters
    const cacheKey = cache.key('books', { page, perPage, query, ...filters });

    // Check cache first - returns cached response if valid
    const cached = cache.get(cacheKey);
    if (cached) {
      console.log('Cache HIT:', cacheKey);
      return Response.json(cached);
    }

    console.log('Cache MISS:', cacheKey);

    // Fetch books from Koha (only on cache miss)
    const result = await getBooks({
      page,
      perPage,
      query,
      filters,
    });

    if (!result.success) {
      console.error('Books fetch failed:', result.error, result.status);
      return errorResponse(result.error || 'Failed to fetch books', result.status || 500);
    }

    // Format book responses
    const books = Array.isArray(result.data)
      ? result.data.map(formatBookResponse)
      : [];

    // Use total from Koha header, or hardcoded total for unfiltered queries
    const hasFilters = query || Object.keys(filters).length > 0;
    const total = result.total || (hasFilters ? null : TOTAL_BOOKS);

    const response = paginatedResponse(books, page, perPage, total);

    // Cache the response for 10 minutes
    cache.set(cacheKey, response, CACHE_TTL.BOOKS_LIST);

    return Response.json(response);

  } catch (error) {
    console.error('Books listing error:', error);
    return errorResponse('Internal server error', 500);
  }
}
