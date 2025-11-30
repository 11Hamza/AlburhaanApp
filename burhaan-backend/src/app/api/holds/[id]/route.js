/**
 * GET /api/holds/[id]
 * Get details of a specific hold
 *
 * PATCH /api/holds/[id]
 * Update a hold (e.g., change pickup location)
 *
 * DELETE /api/holds/[id]
 * Cancel a hold
 */

import { kohaRequest, cancelHold, updateHold, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatHoldResponse, formatBookResponse } from '@/lib/helpers';

export async function GET(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot view holds', 403);
  }

  try {
    const { id } = await params;
    const holdId = parseInt(id, 10);

    if (isNaN(holdId)) {
      return errorResponse('Invalid hold ID', 400);
    }

    // Fetch hold from Koha
    const result = await kohaRequest(`/holds/${holdId}`);

    if (!result.success) {
      if (result.status === 404) {
        return errorResponse('Hold not found', 404);
      }
      return errorResponse(result.error || 'Failed to fetch hold', 500);
    }

    const hold = result.data;

    // Verify this hold belongs to the user
    if (hold.patron_id !== user.patronId) {
      return errorResponse('Unauthorized to view this hold', 403);
    }

    // Get book details
    let bookDetails = null;
    if (hold.biblio_id) {
      const bookResult = await getBookById(hold.biblio_id);
      if (bookResult.success) {
        bookDetails = formatBookResponse(bookResult.data);
      }
    }

    const formattedHold = formatHoldResponse(hold);

    return successResponse({
      ...formattedHold,
      book: bookDetails,
    });

  } catch (error) {
    console.error('Hold detail error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function PATCH(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot update holds', 403);
  }

  try {
    const { id } = await params;
    const holdId = parseInt(id, 10);

    if (isNaN(holdId)) {
      return errorResponse('Invalid hold ID', 400);
    }

    // First verify this hold belongs to the user
    const holdResult = await kohaRequest(`/holds/${holdId}`);

    if (!holdResult.success) {
      if (holdResult.status === 404) {
        return errorResponse('Hold not found', 404);
      }
      return errorResponse('Failed to verify hold', 500);
    }

    if (holdResult.data.patron_id !== user.patronId) {
      return errorResponse('Unauthorized to update this hold', 403);
    }

    // Get update data
    const body = await request.json();
    const { pickupLibraryId, priority, notes } = body;

    const updates = {};
    if (pickupLibraryId) updates.pickup_library_id = pickupLibraryId;
    if (priority !== undefined) updates.priority = priority;
    if (notes !== undefined) updates.notes = notes;

    if (Object.keys(updates).length === 0) {
      return errorResponse('No updates provided', 400);
    }

    // Update hold
    const updateResult = await updateHold(holdId, updates);

    if (!updateResult.success) {
      return errorResponse(updateResult.error || 'Failed to update hold', 500);
    }

    const formattedHold = formatHoldResponse(updateResult.data);

    return successResponse({
      hold: formattedHold,
    }, 'Hold updated successfully');

  } catch (error) {
    console.error('Hold update error:', error);
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

  if (user.isGuest) {
    return errorResponse('Guests cannot cancel holds', 403);
  }

  try {
    const { id } = await params;
    const holdId = parseInt(id, 10);

    if (isNaN(holdId)) {
      return errorResponse('Invalid hold ID', 400);
    }

    // First verify this hold belongs to the user
    const holdResult = await kohaRequest(`/holds/${holdId}`);

    if (!holdResult.success) {
      if (holdResult.status === 404) {
        return errorResponse('Hold not found', 404);
      }
      return errorResponse('Failed to verify hold', 500);
    }

    if (holdResult.data.patron_id !== user.patronId) {
      return errorResponse('Unauthorized to cancel this hold', 403);
    }

    // Cancel hold
    const cancelResult = await cancelHold(holdId);

    if (!cancelResult.success) {
      return errorResponse(cancelResult.error || 'Failed to cancel hold', 500);
    }

    return successResponse(null, 'Hold cancelled successfully');

  } catch (error) {
    console.error('Hold cancellation error:', error);
    return errorResponse('Internal server error', 500);
  }
}
