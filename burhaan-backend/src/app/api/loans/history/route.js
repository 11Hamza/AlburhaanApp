/**
 * GET /api/loans/history
 * Get the current user's loan history (past checkouts)
 */

import { getPatronCheckoutHistory, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatBookResponse, getPaginationParams, paginatedResponse } from '@/lib/helpers';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests do not have loan history', 403);
  }

  try {
    const { searchParams } = new URL(request.url);
    const { page, perPage } = getPaginationParams(searchParams);

    // Fetch checkout history from Koha
    const historyResult = await getPatronCheckoutHistory(user.patronId);

    if (!historyResult.success) {
      return errorResponse(historyResult.error || 'Failed to fetch history', 500);
    }

    let history = Array.isArray(historyResult.data) ? historyResult.data : [];

    // Sort by return date (most recent first)
    history.sort((a, b) => {
      const dateA = new Date(a.returndate || a.timestamp);
      const dateB = new Date(b.returndate || b.timestamp);
      return dateB - dateA;
    });

    // Apply pagination
    const startIndex = (page - 1) * perPage;
    const paginatedHistory = history.slice(startIndex, startIndex + perPage);

    // Enrich with book details
    const enrichedHistory = await Promise.all(
      paginatedHistory.map(async (checkout) => {
        let bookDetails = null;

        if (checkout.biblio_id) {
          const bookResult = await getBookById(checkout.biblio_id);
          if (bookResult.success) {
            bookDetails = formatBookResponse(bookResult.data);
          }
        }

        return {
          checkoutId: checkout.checkout_id || checkout.issue_id,
          itemId: checkout.item_id,
          biblioId: checkout.biblio_id,
          issueDate: checkout.issuedate || checkout.issue_date,
          returnDate: checkout.returndate || checkout.return_date,
          book: bookDetails,
        };
      })
    );

    return Response.json(paginatedResponse(enrichedHistory, page, perPage, history.length));

  } catch (error) {
    console.error('Loan history error:', error);
    return errorResponse('Internal server error', 500);
  }
}
