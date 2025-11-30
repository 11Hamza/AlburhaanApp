/**
 * GET /api/loans/[id]
 * Get details of a specific loan
 */

import { kohaRequest, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatCheckoutResponse } from '@/lib/helpers';

export async function GET(request, { params }) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot view loan details', 403);
  }

  try {
    const { id } = await params;
    const checkoutId = parseInt(id, 10);

    if (isNaN(checkoutId)) {
      return errorResponse('Invalid loan ID', 400);
    }

    // Fetch checkout from Koha
    const result = await kohaRequest(`/checkouts/${checkoutId}`);

    if (!result.success) {
      if (result.status === 404) {
        return errorResponse('Loan not found', 404);
      }
      return errorResponse(result.error || 'Failed to fetch loan', 500);
    }

    const checkout = result.data;

    // Verify this checkout belongs to the user
    if (checkout.patron_id !== user.patronId) {
      return errorResponse('Unauthorized to view this loan', 403);
    }

    // Get book details
    let bookDetails = null;
    if (checkout.biblio_id) {
      const bookResult = await getBookById(checkout.biblio_id);
      if (bookResult.success) {
        bookDetails = bookResult.data;
      }
    }

    // Check renewability
    const renewabilityResult = await kohaRequest(`/checkouts/${checkoutId}/allows_renewal`);
    const canRenew = renewabilityResult.success &&
                     renewabilityResult.data?.allows_renewal === true;
    const renewalError = renewabilityResult.data?.error || null;

    const formattedCheckout = formatCheckoutResponse(checkout, bookDetails);

    return successResponse({
      ...formattedCheckout,
      canRenew,
      renewalError,
    });

  } catch (error) {
    console.error('Loan detail error:', error);
    return errorResponse('Internal server error', 500);
  }
}
