/**
 * POST /api/loans/[id]/renew
 * Renew a specific loan
 */

import { renewCheckout, kohaRequest, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatCheckoutResponse } from '@/lib/helpers';

export async function POST(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot renew loans', 403);
  }

  try {
    const { id } = await params;
    const checkoutId = parseInt(id, 10);

    if (isNaN(checkoutId)) {
      return errorResponse('Invalid loan ID', 400);
    }

    // First verify this checkout belongs to the user
    const checkoutResult = await kohaRequest(`/checkouts/${checkoutId}`);

    if (!checkoutResult.success) {
      if (checkoutResult.status === 404) {
        return errorResponse('Loan not found', 404);
      }
      return errorResponse('Failed to verify loan', 500);
    }

    if (checkoutResult.data.patron_id !== user.patronId) {
      return errorResponse('Unauthorized to renew this loan', 403);
    }

    // Attempt renewal
    const renewResult = await renewCheckout(checkoutId);

    if (!renewResult.success) {
      // Common renewal errors
      const errorMessages = {
        'too_many_renewals': 'Maximum renewal limit reached',
        'on_reserve': 'This item is on hold for another patron',
        'overdue': 'Cannot renew overdue items',
        'item_denied_renewal': 'Renewal not allowed for this item type',
      };

      const errorCode = renewResult.data?.error_code || renewResult.error;
      const message = errorMessages[errorCode] || renewResult.error || 'Renewal failed';

      return errorResponse(message, 400, errorCode);
    }

    // Get updated checkout details
    const updatedCheckout = await kohaRequest(`/checkouts/${checkoutId}`);
    let bookDetails = null;

    if (updatedCheckout.success && updatedCheckout.data.biblio_id) {
      const bookResult = await getBookById(updatedCheckout.data.biblio_id);
      if (bookResult.success) {
        bookDetails = bookResult.data;
      }
    }

    const formattedCheckout = formatCheckoutResponse(
      updatedCheckout.data || renewResult.data,
      bookDetails
    );

    return successResponse({
      ...formattedCheckout,
      renewed: true,
      newDueDate: renewResult.data?.due_date || formattedCheckout.dueDate,
    }, 'Loan renewed successfully');

  } catch (error) {
    console.error('Loan renewal error:', error);
    return errorResponse('Internal server error', 500);
  }
}
