/**
 * GET /api/holds
 * Get the current user's holds (reservations)
 *
 * POST /api/holds
 * Place a new hold on a book
 */

import { getPatronHolds, placeHold, getBookById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatHoldResponse, formatBookResponse, validateRequired } from '@/lib/helpers';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot place holds', 403);
  }

  try {
    // Fetch holds from Koha
    const holdsResult = await getPatronHolds(user.patronId);

    if (!holdsResult.success) {
      return errorResponse(holdsResult.error || 'Failed to fetch holds', 500);
    }

    const holds = Array.isArray(holdsResult.data) ? holdsResult.data : [];

    // Enrich with book details
    const enrichedHolds = await Promise.all(
      holds.map(async (hold) => {
        let bookDetails = null;

        if (hold.biblio_id) {
          const bookResult = await getBookById(hold.biblio_id);
          if (bookResult.success) {
            bookDetails = formatBookResponse(bookResult.data);
          }
        }

        const formattedHold = formatHoldResponse(hold);

        // Determine status text
        let statusText = 'Pending';
        if (hold.status === 'W' || hold.status === 'waiting') {
          statusText = 'Ready for Pickup';
        } else if (hold.status === 'T' || hold.status === 'transit') {
          statusText = 'In Transit';
        }

        return {
          ...formattedHold,
          statusText,
          book: bookDetails,
        };
      })
    );

    // Sort by hold date (newest first)
    enrichedHolds.sort((a, b) => {
      const dateA = new Date(a.holdDate);
      const dateB = new Date(b.holdDate);
      return dateB - dateA;
    });

    // Calculate summary
    const readyCount = enrichedHolds.filter(h =>
      h.status === 'W' || h.status === 'waiting'
    ).length;

    return successResponse({
      holds: enrichedHolds,
      summary: {
        total: enrichedHolds.length,
        ready: readyCount,
        pending: enrichedHolds.length - readyCount,
      },
    });

  } catch (error) {
    console.error('Holds fetch error:', error);
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
    return errorResponse('Guests cannot place holds', 403);
  }

  try {
    const body = await request.json();
    console.log('DEBUG: Place hold request body:', body);
    console.log('DEBUG: User patronId:', user.patronId);

    // Validate required fields
    const validation = validateRequired(body, ['biblioId', 'pickupLibraryId']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const { biblioId, pickupLibraryId, notes } = body;

    // Place hold via Koha
    const holdResult = await placeHold({
      patronId: user.patronId,
      biblioId,
      pickupLibraryId,
      notes: notes || '',
    });

    console.log('DEBUG: Koha placeHold result:', JSON.stringify(holdResult, null, 2));

    if (!holdResult.success) {
      // Common hold errors
      const errorMessages = {
        'hold_not_allowed': 'Holds are not allowed on this item',
        'item_already_on_hold': 'You already have a hold on this item',
        'max_holds_reached': 'You have reached your maximum number of holds',
        'patron_not_found': 'Patron not found',
        'biblio_not_found': 'Book not found',
      };

      const errorCode = holdResult.data?.error_code || holdResult.error;
      const message = errorMessages[errorCode] || holdResult.error || 'Failed to place hold';

      return errorResponse(message, 400, errorCode);
    }

    // Get book details for response
    let bookDetails = null;
    const bookResult = await getBookById(biblioId);
    if (bookResult.success) {
      bookDetails = formatBookResponse(bookResult.data);
    }

    const formattedHold = formatHoldResponse(holdResult.data);

    return successResponse({
      hold: {
        ...formattedHold,
        book: bookDetails,
      },
    }, 'Hold placed successfully');

  } catch (error) {
    console.error('Place hold error:', error);
    return errorResponse('Internal server error', 500);
  }
}
