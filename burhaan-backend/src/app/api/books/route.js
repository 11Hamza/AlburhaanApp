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

    if (!result.success) {
      return errorResponse(result.error || 'Failed to fetch books', result.status || 500);
    }

    // Format book responses
    const books = Array.isArray(result.data)
      ? result.data.map(formatBookResponse)
      : [];

    return Response.json(paginatedResponse(books, page, perPage));

  } catch (error) {
    console.error('Books listing error:', error);
    return errorResponse('Internal server error', 500);
  }
}
