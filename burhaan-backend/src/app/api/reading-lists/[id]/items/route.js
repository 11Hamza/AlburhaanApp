/**
 * POST /api/reading-lists/[id]/items
 * Add a book to a reading list
 */

import { getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatBookResponse, validateRequired } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function POST(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;
  const { id: listId } = await params;

  if (user.isGuest) {
    return errorResponse('Guests cannot modify reading lists', 403);
  }

  try {
    // Get the reading list
    const list = await prisma.readingList.findUnique({
      where: { id: listId },
    });

    if (!list) {
      return errorResponse('Reading list not found', 404);
    }

    // Check ownership
    if (list.patronId !== user.patronId) {
      return errorResponse('Unauthorized', 403);
    }

    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['biblioId']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const { biblioId, notes } = body;
    const biblioIdInt = parseInt(biblioId, 10);

    if (isNaN(biblioIdInt)) {
      return errorResponse('Invalid book ID', 400);
    }

    // Verify book exists in Koha
    const bookResult = await getBookById(biblioIdInt);
    if (!bookResult.success) {
      return errorResponse('Book not found', 404);
    }

    // Check if book is already in the list
    const existing = await prisma.readingListItem.findUnique({
      where: {
        listId_biblioId: {
          listId,
          biblioId: biblioIdInt,
        },
      },
    });

    if (existing) {
      return errorResponse('Book is already in this list', 409, 'ALREADY_IN_LIST');
    }

    // Add to list
    const item = await prisma.readingListItem.create({
      data: {
        listId,
        biblioId: biblioIdInt,
        notes: notes?.trim() || null,
      },
    });

    const bookDetails = formatBookResponse(bookResult.data);

    return successResponse({
      id: item.id,
      biblioId: item.biblioId,
      notes: item.notes,
      addedAt: item.addedAt,
      book: bookDetails,
    }, 'Book added to reading list');

  } catch (error) {
    console.error('Add to reading list error:', error);
    return errorResponse('Internal server error', 500);
  }
}
