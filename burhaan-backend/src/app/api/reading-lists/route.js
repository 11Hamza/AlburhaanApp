/**
 * GET /api/reading-lists
 * Get all reading lists for the current user
 *
 * POST /api/reading-lists
 * Create a new reading list
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { validateRequired, getPaginationParams } from '@/lib/helpers';
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
      lists: [],
      total: 0,
    });
  }

  try {
    // Get all reading lists for this user
    const lists = await prisma.readingList.findMany({
      where: { patronId: user.patronId },
      orderBy: { updatedAt: 'desc' },
    });

    return successResponse({
      lists: lists.map(list => ({
        id: list.id,
        name: list.name,
        description: list.description,
        isPublic: list.isPublic || false,
        itemCount: list.itemCount || 0,
        createdAt: list.createdAt,
        updatedAt: list.updatedAt,
      })),
      total: lists.length,
    });

  } catch (error) {
    console.error('Reading lists fetch error:', error);
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
    return errorResponse('Guests cannot create reading lists', 403);
  }

  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['name']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const { name, description, isPublic } = body;

    // Create the reading list
    const list = await prisma.readingList.create({
      data: {
        patronId: user.patronId,
        name: name.trim(),
        description: description?.trim() || null,
        isPublic: isPublic || false,
      },
    });

    return successResponse({
      id: list.id,
      name: list.name,
      description: list.description,
      isPublic: list.isPublic,
      itemCount: 0,
      createdAt: list.createdAt,
      updatedAt: list.updatedAt,
    }, 'Reading list created');

  } catch (error) {
    console.error('Reading list creation error:', error);
    return errorResponse('Internal server error', 500);
  }
}
