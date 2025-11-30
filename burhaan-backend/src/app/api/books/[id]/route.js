/**
 * GET /api/books/[id]
 * Get detailed information about a specific book
 */

import { getBookById } from '@/lib/koha';
import { formatBookResponse } from '@/lib/helpers';
import { errorResponse, successResponse, getCurrentUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function GET(request, { params }) {
  try {
    const { id } = await params;
    const biblioId = parseInt(id, 10);

    if (isNaN(biblioId)) {
      return errorResponse('Invalid book ID', 400);
    }

    // Fetch book details from Koha
    const result = await getBookById(biblioId);

    if (!result.success) {
      if (result.status === 404) {
        return errorResponse('Book not found', 404);
      }
      return errorResponse(result.error || 'Failed to fetch book details', result.status || 500);
    }

    // Track recently viewed if user is authenticated
    const { authenticated, user } = getCurrentUser(request);
    if (authenticated && user && !user.isGuest) {
      try {
        await prisma.recentlyViewed.upsert({
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
        });
      } catch (dbError) {
        console.warn('Failed to track recently viewed:', dbError.message);
      }
    }

    // Format and return book details
    const book = formatBookResponse(result.data);

    return successResponse(book);

  } catch (error) {
    console.error('Book detail error:', error);
    return errorResponse('Internal server error', 500);
  }
}
