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

    // Fetch patron's holds and find the specific one
    // (Koha may not support GET /holds/{id} for individual hold lookup)
    const patronHoldsResult = await kohaRequest(`/holds?patron_id=${user.patronId}`);

    if (!patronHoldsResult.success) {
      return errorResponse('Failed to fetch holds', 500);
    }

    const patronHolds = Array.isArray(patronHoldsResult.data) ? patronHoldsResult.data : [];
    const hold = patronHolds.find(h => h.hold_id === holdId);

    if (!hold) {
      return errorResponse('Hold not found', 404);
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

    // Verify this hold belongs to the user by fetching all their holds
    const patronHoldsResult = await kohaRequest(`/holds?patron_id=${user.patronId}`);

    if (!patronHoldsResult.success) {
      return errorResponse('Failed to verify hold ownership', 500);
    }

    const patronHolds = Array.isArray(patronHoldsResult.data) ? patronHoldsResult.data : [];
    const holdBelongsToUser = patronHolds.some(h => h.hold_id === holdId);

    if (!holdBelongsToUser) {
      return errorResponse('Hold not found or unauthorized', 404);
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

    console.log('DEBUG: Cancel hold request - holdId:', holdId, 'patronId:', user.patronId);

    if (isNaN(holdId)) {
      return errorResponse('Invalid hold ID', 400);
    }

    // Verify this hold belongs to the user by fetching all their holds
    // (Koha may not support GET /holds/{id} for individual hold lookup)
    const patronHoldsResult = await kohaRequest(`/holds?patron_id=${user.patronId}`);
    console.log('DEBUG: Patron holds lookup result:', JSON.stringify(patronHoldsResult, null, 2));

    if (!patronHoldsResult.success) {
      return errorResponse('Failed to verify hold ownership', 500);
    }

    const patronHolds = Array.isArray(patronHoldsResult.data) ? patronHoldsResult.data : [];
    const holdBelongsToUser = patronHolds.some(h => h.hold_id === holdId);
    console.log('DEBUG: Hold belongs to user:', holdBelongsToUser);

    if (!holdBelongsToUser) {
      return errorResponse('Hold not found or unauthorized', 404);
    }

    // Cancel hold
    const cancelResult = await cancelHold(holdId);
    console.log('DEBUG: Cancel result:', JSON.stringify(cancelResult, null, 2));

    if (!cancelResult.success) {
      // Map common error codes
      const errorMsg = cancelResult.error || 'Failed to cancel hold';
      return errorResponse(errorMsg, cancelResult.status || 500);
    }

    return successResponse(null, 'Hold cancelled successfully');

  } catch (error) {
    console.error('Hold cancellation error:', error);
    return errorResponse('Internal server error', 500);
  }
}
