/**
 * GET /api/loans
 * Get the current user's active loans (checkouts)
 */

import { getPatronCheckouts, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatCheckoutResponse, formatBookResponse } from '@/lib/helpers';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot have loans', 403);
  }

  try {
    // Fetch checkouts from Koha
    const checkoutsResult = await getPatronCheckouts(user.patronId);

    if (!checkoutsResult.success) {
      return errorResponse(checkoutsResult.error || 'Failed to fetch loans', 500);
    }

    const checkouts = Array.isArray(checkoutsResult.data) ? checkoutsResult.data : [];

    // Enrich with book details
    const enrichedCheckouts = await Promise.all(
      checkouts.map(async (checkout) => {
        let bookDetails = null;

        // Try to get book details if we have biblio_id
        if (checkout.biblio_id) {
          const bookResult = await getBookById(checkout.biblio_id);
          if (bookResult.success) {
            bookDetails = bookResult.data;
          }
        }

        return formatCheckoutResponse(checkout, bookDetails);
      })
    );

    // Sort by due date (soonest first)
    enrichedCheckouts.sort((a, b) => {
      const dateA = new Date(a.dueDate);
      const dateB = new Date(b.dueDate);
      return dateA - dateB;
    });

    // Calculate summary
    const now = new Date();
    const overdueCount = enrichedCheckouts.filter(c => c.isOverdue).length;
    const dueSoonCount = enrichedCheckouts.filter(c =>
      !c.isOverdue && c.daysUntilDue <= 3
    ).length;

    return successResponse({
      loans: enrichedCheckouts,
      summary: {
        total: enrichedCheckouts.length,
        overdue: overdueCount,
        dueSoon: dueSoonCount, // Due within 3 days
      },
    });

  } catch (error) {
    console.error('Loans fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
