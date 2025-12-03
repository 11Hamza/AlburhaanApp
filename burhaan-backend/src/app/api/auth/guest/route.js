/**
 * POST /api/auth/guest
 * Login as guest user using pre-configured Koha guest account
 */

import { validateCredentials, getPatronByCardNumber } from '@/lib/koha';
import { generateToken, successResponse, errorResponse, getTokenExpiry } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function POST(request) {
  try {
    // Get guest credentials from environment
    const guestCardNumber = process.env.KOHA_GUEST_CARDNUMBER;
    const guestPassword = process.env.KOHA_GUEST_PASSWORD;

    if (!guestCardNumber || !guestPassword) {
      console.error('Guest credentials not configured');
      return errorResponse('Guest login not available', 503);
    }

    // Validate guest credentials with Koha
    const isValid = await validateCredentials(guestCardNumber, guestPassword);

    if (!isValid) {
      console.error('Guest credentials invalid in Koha');
      return errorResponse('Guest login unavailable', 503);
    }

    // Get guest patron details from Koha
    const patron = await getPatronByCardNumber(guestCardNumber);

    if (!patron) {
      console.error('Guest patron not found in Koha');
      return errorResponse('Guest account not found', 503);
    }

    // Add guest flag to patron object
    const guestPatron = {
      ...patron,
      isGuest: true,
    };

    // Generate JWT token
    const token = generateToken(guestPatron);
    const expiresAt = getTokenExpiry();

    // Store session
    try {
      await prisma.session.create({
        data: {
          patronId: patron.patron_id,
          token,
          expiresAt,
        },
      });
    } catch (dbError) {
      console.warn('Guest session storage failed (continuing without persistence):', dbError.message);
    }

    return successResponse({
      token,
      expiresAt: expiresAt.toISOString(),
      user: {
        patronId: patron.patron_id,
        cardNumber: patron.cardnumber,
        firstName: patron.firstname,
        surname: patron.surname,
        email: patron.email || null,
        libraryId: patron.library_id,
        isGuest: true,
      },
    }, 'Guest session created');

  } catch (error) {
    console.error('Guest session error:', error);
    return errorResponse('Failed to create guest session', 500);
  }
}
