/**
 * POST /api/auth/guest
 * Get a guest session token for browsing without login
 */

import { generateToken, successResponse, errorResponse, getTokenExpiry } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function POST(request) {
  try {
    // Create a guest patron object
    const guestPatron = {
      patron_id: 0, // Special ID for guest
      cardnumber: 'GUEST',
      firstname: 'Guest',
      surname: 'User',
      email: null,
      library_id: null,
      category_id: 'GUEST',
      isGuest: true,
    };

    // Generate JWT token for guest
    const token = generateToken(guestPatron);
    const expiresAt = getTokenExpiry();

    // Optionally store guest session
    try {
      await prisma.session.create({
        data: {
          patronId: 0,
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
        patronId: 0,
        cardNumber: 'GUEST',
        firstName: 'Guest',
        surname: 'User',
        email: null,
        libraryId: null,
        isGuest: true,
      },
    }, 'Guest session created');

  } catch (error) {
    console.error('Guest session error:', error);
    return errorResponse('Failed to create guest session', 500);
  }
}
