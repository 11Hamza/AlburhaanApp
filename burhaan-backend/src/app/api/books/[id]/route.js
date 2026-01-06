/**
 * GET /api/books/[id]
 * Get detailed information about a specific book
 */

import { getBookById } from '@/lib/koha';
import { formatBookResponse } from '@/lib/helpers';
import { errorResponse, successResponse, getCurrentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import cache, { CACHE_TTL } from '@/lib/cache';

export async function GET(request, { params }) {
  try {
    const { id } = await params;
    const biblioId = parseInt(id, 10);

    if (isNaN(biblioId)) {
      return errorResponse('Invalid book ID', 400);
    }

    // Check cache first for book data
    const cacheKey = `book:${biblioId}`;
    let book = cache.get(cacheKey);

    if (!book) {
      // Cache miss - fetch from Koha
      const result = await getBookById(biblioId);

      if (!result.success) {
        if (result.status === 404) {
          return errorResponse('Book not found', 404);
        }
        return errorResponse(result.error || 'Failed to fetch book details', result.status || 500);
      }

      book = formatBookResponse(result.data);
      cache.set(cacheKey, book, CACHE_TTL.BOOK_DETAIL);
    }

    // Track recently viewed if user is authenticated (don't block response)
    const { authenticated, user } = getCurrentUser(request);
    if (authenticated && user && !user.isGuest) {
      prisma.recentlyViewed.upsert({
        where: {
          patronId_biblioId: {
            patronId: user.patronId,
            biblioId,
          },
        },
        update: {
          viewedAt: new Date(),
        },
        create: {
          patronId: user.patronId,
          biblioId,
          viewedAt: new Date(),
        },
      }).catch(dbError => {
        console.warn('Failed to track recently viewed:', dbError.message);
      });
    }

    return successResponse(book);

  } catch (error) {
    console.error('Book detail error:', error);
    return errorResponse('Internal server error', 500);
  }
}
