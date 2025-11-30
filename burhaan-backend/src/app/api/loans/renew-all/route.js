/**
 * POST /api/loans/renew-all
 * Renew all eligible loans for the current user
 */

import { getPatronCheckouts, renewCheckout, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatCheckoutResponse } from '@/lib/helpers';

export async function POST(request) {
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
    // Get all current checkouts
    const checkoutsResult = await getPatronCheckouts(user.patronId);

    if (!checkoutsResult.success) {
      return errorResponse('Failed to fetch loans', 500);
    }

    const checkouts = Array.isArray(checkoutsResult.data) ? checkoutsResult.data : [];

    if (checkouts.length === 0) {
      return successResponse({
        renewed: [],
        failed: [],
        summary: {
          total: 0,
          renewed: 0,
          failed: 0,
        },
      }, 'No loans to renew');
    }

    // Attempt to renew each checkout
    const results = await Promise.all(
      checkouts.map(async (checkout) => {
        const checkoutId = checkout.checkout_id;

        try {
          const renewResult = await renewCheckout(checkoutId);

          // Get book details
          let bookDetails = null;
          if (checkout.biblio_id) {
            const bookResult = await getBookById(checkout.biblio_id);
            if (bookResult.success) {
              bookDetails = bookResult.data;
            }
          }

          if (renewResult.success) {
            return {
              success: true,
              checkout: formatCheckoutResponse(
                { ...checkout, due_date: renewResult.data?.due_date || checkout.due_date },
                bookDetails
              ),
              newDueDate: renewResult.data?.due_date,
            };
          } else {
            return {
              success: false,
              checkout: formatCheckoutResponse(checkout, bookDetails),
              error: renewResult.error || 'Renewal failed',
              errorCode: renewResult.data?.error_code,
            };
          }
        } catch (err) {
          return {
            success: false,
            checkoutId,
            error: err.message,
          };
        }
      })
    );

    const renewed = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    return successResponse({
      renewed: renewed.map(r => ({
        checkout: r.checkout,
        newDueDate: r.newDueDate,
      })),
      failed: failed.map(r => ({
        checkout: r.checkout,
        error: r.error,
        errorCode: r.errorCode,
      })),
      summary: {
        total: checkouts.length,
        renewed: renewed.length,
        failed: failed.length,
      },
    }, `Renewed ${renewed.length} of ${checkouts.length} loans`);

  } catch (error) {
    console.error('Renew all error:', error);
    return errorResponse('Internal server error', 500);
  }
}
