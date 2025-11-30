/**
 * DELETE /api/favorites/[id]
 * Remove a book from favorites
 *
 * Note: [id] can be either the favorite record ID or the biblio_id
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function DELETE(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot manage favorites', 403);
  }

  try {
    const { id } = await params;

    // Check if this is a UUID (favorite ID) or number (biblio ID)
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    const biblioId = parseInt(id, 10);

    let favorite;

    if (isUuid) {
      // Delete by favorite ID
      favorite = await prisma.favorite.findUnique({
        where: { id },
      });

      if (!favorite) {
        return errorResponse('Favorite not found', 404);
      }

      if (favorite.patronId !== user.patronId) {
        return errorResponse('Unauthorized', 403);
      }

      await prisma.favorite.delete({
        where: { id },
      });
    } else if (!isNaN(biblioId)) {
      // Delete by biblio ID
      favorite = await prisma.favorite.findUnique({
        where: {
          patronId_biblioId: {
            patronId: user.patronId,
            biblioId,
          },
        },
      });

      if (!favorite) {
        return errorResponse('Book is not in favorites', 404);
      }

      await prisma.favorite.delete({
        where: {
          patronId_biblioId: {
            patronId: user.patronId,
            biblioId,
          },
        },
      });
    } else {
      return errorResponse('Invalid ID format', 400);
    }

    return successResponse(null, 'Book removed from favorites');

  } catch (error) {
    console.error('Remove favorite error:', error);
    return errorResponse('Internal server error', 500);
  }
}

/**
 * GET /api/favorites/[id]
 * Check if a book is in favorites
 */
export async function GET(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return successResponse({ isFavorite: false });
  }

  try {
    const { id } = await params;
    const biblioId = parseInt(id, 10);

    if (isNaN(biblioId)) {
      return errorResponse('Invalid book ID', 400);
    }

    // Check if book is in favorites
    const favorite = await prisma.favorite.findUnique({
      where: {
        patronId_biblioId: {
          patronId: user.patronId,
          biblioId,
        },
      },
    });

    return successResponse({
      isFavorite: !!favorite,
      favoriteId: favorite?.id || null,
      addedAt: favorite?.createdAt || null,
    });

  } catch (error) {
    console.error('Check favorite error:', error);
    return errorResponse('Internal server error', 500);
  }
}
