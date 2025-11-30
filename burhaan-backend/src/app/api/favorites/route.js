/**
 * GET /api/favorites
 * Get the current user's favorite books
 *
 * POST /api/favorites
 * Add a book to favorites
 */

import { getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatBookResponse, getPaginationParams, paginatedResponse, validateRequired } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return successResponse({
      favorites: [],
      total: 0,
    });
  }

  try {
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);

    // Get favorites from database
    const favorites = await prisma.favorite.findMany({
      where: { patronId: user.patronId },
      orderBy: { createdAt: 'desc' },
    });

    // Apply pagination
    const startIndex = (page - 1) * perPage;
    const paginatedFavorites = favorites.slice(startIndex, startIndex + perPage);

    // Enrich with book details from Koha
    const enrichedFavorites = await Promise.all(
      paginatedFavorites.map(async (favorite) => {
        let bookDetails = null;

        const bookResult = await getBookById(favorite.biblioId);
        if (bookResult.success) {
          bookDetails = formatBookResponse(bookResult.data);
        }

        return {
          id: favorite.id,
          biblioId: favorite.biblioId,
          addedAt: favorite.createdAt,
          book: bookDetails,
        };
      })
    );

    return Response.json(paginatedResponse(enrichedFavorites, page, perPage, favorites.length));

  } catch (error) {
    console.error('Favorites fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function POST(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot save favorites', 403);
  }

  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['biblioId']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const { biblioId } = body;
    const biblioIdInt = parseInt(biblioId, 10);

    if (isNaN(biblioIdInt)) {
      return errorResponse('Invalid book ID', 400);
    }

    // Verify book exists in Koha
    const bookResult = await getBookById(biblioIdInt);
    if (!bookResult.success) {
      return errorResponse('Book not found', 404);
    }

    // Check if already favorited
    const existing = await prisma.favorite.findUnique({
      where: {
        patronId_biblioId: {
          patronId: user.patronId,
          biblioId: biblioIdInt,
        },
      },
    });

    if (existing) {
      return errorResponse('Book is already in favorites', 409, 'ALREADY_FAVORITED');
    }

    // Add to favorites
    const favorite = await prisma.favorite.create({
      data: {
        patronId: user.patronId,
        biblioId: biblioIdInt,
      },
    });

    const bookDetails = formatBookResponse(bookResult.data);

    return successResponse({
      id: favorite.id,
      biblioId: favorite.biblioId,
      addedAt: favorite.createdAt,
      book: bookDetails,
    }, 'Book added to favorites');

  } catch (error) {
    console.error('Add favorite error:', error);
    return errorResponse('Internal server error', 500);
  }
}
