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
      // Map Koha error codes to user-friendly messages
      const errorMessages = {
        // Standard Koha error codes
        'hold_not_allowed': 'Holds are not allowed on this item',
        'Hold_not_allowed': 'Holds are not allowed on this item',
        'already_on_hold': 'You already have a hold on this book',
        'item_already_on_hold': 'You already have a hold on this item',
        'too_many_holds': 'You have reached your maximum number of holds. Please cancel an existing hold first.',
        'max_holds_reached': 'You have reached your maximum number of holds',
        'on_shelf_holds_not_allowed': 'This book is currently available on the shelf. Please visit the library to borrow it.',
        'patron_not_found': 'Your library account was not found',
        'biblio_not_found': 'This book could not be found in the catalog',
        'no_available_items': 'No copies of this book are available for holds',
        'item_level_hold_not_allowed': 'Item-level holds are not allowed',
        'patron_expired': 'Your library membership has expired. Please renew your membership.',
        'patron_debarred': 'Your account is blocked. Please contact the library.',
        'debt_limit_exceeded': 'You have outstanding fines that prevent placing holds. Please pay your fines first.',
      };

      // Get error code from multiple possible locations
      const errorCode = holdResult.errorCode
        || holdResult.data?.error_code
        || holdResult.data?.error
        || null;

      // Get error message - check multiple locations
      let message = errorMessages[errorCode];

      if (!message) {
        // Try to extract message from error response
        const rawError = holdResult.error || holdResult.data?.error || holdResult.data?.message;

        // Check if error contains recognizable patterns
        if (typeof rawError === 'string') {
          if (rawError.toLowerCase().includes('already') && rawError.toLowerCase().includes('hold')) {
            message = 'You already have a hold on this book';
          } else if (rawError.toLowerCase().includes('maximum') || rawError.toLowerCase().includes('too many')) {
            message = 'You have reached your maximum number of holds';
          } else if (rawError.toLowerCase().includes('not allowed')) {
            message = 'Holds are not allowed on this item';
          } else if (rawError.toLowerCase().includes('available') || rawError.toLowerCase().includes('on shelf')) {
            message = 'This book is currently available. Please visit the library to borrow it.';
          } else if (rawError.toLowerCase().includes('expired')) {
            message = 'Your library membership has expired';
          } else if (rawError.toLowerCase().includes('blocked') || rawError.toLowerCase().includes('debarred')) {
            message = 'Your account is blocked. Please contact the library.';
          } else {
            message = rawError;
          }
        } else {
          message = 'Unable to place hold. Please try again or contact the library.';
        }
      }

      console.log('DEBUG: Hold error - code:', errorCode, 'message:', message);
      return errorResponse(message, holdResult.status || 400, errorCode);
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
