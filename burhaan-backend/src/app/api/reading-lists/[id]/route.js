/**
 * GET /api/reading-lists/[id]
 * Get a specific reading list with its items
 *
 * PUT /api/reading-lists/[id]
 * Update a reading list
 *
 * DELETE /api/reading-lists/[id]
 * Delete a reading list
 */

import { getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatBookResponse, getPaginationParams } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function GET(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;
  const { id } = await params;

  try {
    // Get the reading list
    const list = await prisma.readingList.findUnique({
      where: { id },
    });

    if (!list) {
      return errorResponse('Reading list not found', 404);
    }

    // Check ownership (unless it's public)
    if (list.patronId !== user.patronId && !list.isPublic) {
      return errorResponse('Unauthorized', 403);
    }

    // Get pagination params
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);

    // Get items in this list
    const items = await prisma.readingListItem.findMany({
      where: { listId: id },
      orderBy: { addedAt: 'desc' },
    });

    // Apply pagination
    const startIndex = (page - 1) * perPage;
    const paginatedItems = items.slice(startIndex, startIndex + perPage);

    // Enrich items with book details
    const enrichedItems = await Promise.all(
      paginatedItems.map(async (item) => {
        let bookDetails = null;

        const bookResult = await getBookById(item.biblioId);
        if (bookResult.success) {
          bookDetails = formatBookResponse(bookResult.data);
        }

        return {
          id: item.id,
          biblioId: item.biblioId,
          notes: item.notes,
          addedAt: item.addedAt,
          book: bookDetails,
        };
      })
    );

    return successResponse({
      list: {
        id: list.id,
        name: list.name,
        description: list.description,
        isPublic: list.isPublic,
        itemCount: items.length,
        createdAt: list.createdAt,
        updatedAt: list.updatedAt,
        isOwner: list.patronId === user.patronId,
      },
      items: enrichedItems,
      pagination: {
        page,
        perPage,
        total: items.length,
        totalPages: Math.ceil(items.length / perPage),
      },
    });

  } catch (error) {
    console.error('Reading list fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function PUT(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;
  const { id } = await params;

  try {
    // Get the reading list
    const list = await prisma.readingList.findUnique({
      where: { id },
    });

    if (!list) {
      return errorResponse('Reading list not found', 404);
    }

    // Check ownership
    if (list.patronId !== user.patronId) {
      return errorResponse('Unauthorized', 403);
    }

    const body = await request.json();
    const { name, description, isPublic } = body;

    // Update the list
    const updatedList = await prisma.readingList.update({
      where: { id },
      data: {
        ...(name && { name: name.trim() }),
        ...(description !== undefined && { description: description?.trim() || null }),
        ...(typeof isPublic === 'boolean' && { isPublic }),
      },
    });

    return successResponse({
      id: updatedList.id,
      name: updatedList.name,
      description: updatedList.description,
      isPublic: updatedList.isPublic,
      itemCount: updatedList.itemCount,
      createdAt: updatedList.createdAt,
      updatedAt: updatedList.updatedAt,
    }, 'Reading list updated');

  } catch (error) {
    console.error('Reading list update error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function DELETE(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;
  const { id } = await params;

  try {
    // Get the reading list
    const list = await prisma.readingList.findUnique({
      where: { id },
    });

    if (!list) {
      return errorResponse('Reading list not found', 404);
    }

    // Check ownership
    if (list.patronId !== user.patronId) {
      return errorResponse('Unauthorized', 403);
    }

    // Delete the list (items will be cascade deleted in db.js)
    await prisma.readingList.delete({
      where: { id },
    });

    return successResponse({
      deleted: true,
    }, 'Reading list deleted');

  } catch (error) {
    console.error('Reading list delete error:', error);
    return errorResponse('Internal server error', 500);
  }
}
