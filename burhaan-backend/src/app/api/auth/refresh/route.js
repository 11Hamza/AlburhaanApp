/**
 * POST /api/auth/refresh
 * Refresh an existing JWT token
 */

import { verifyToken, extractToken, generateToken, errorResponse, successResponse, getTokenExpiry } from '@/lib/auth';
import { getPatronById } from '@/lib/koha';
import { prisma } from '@/lib/db';

export async function POST(request) {
  try {
    const authHeader = request.headers.get('authorization');
    const oldToken = extractToken(authHeader);

    if (!oldToken) {
      return errorResponse('No token provided', 400);
    }

    // Verify the old token (even if expired, we can still refresh within a grace period)
    const { valid, decoded, error } = verifyToken(oldToken);

    if (!valid) {
      // Check if it's just expired (not invalid signature)
      if (error !== 'jwt expired') {
        return errorResponse('Invalid token', 401, 'INVALID_TOKEN');
      }
    }

    // For guests, just issue a new guest token
    if (decoded?.isGuest) {
      const guestPatron = {
        patron_id: 0,
        cardnumber: 'GUEST',
        firstname: 'Guest',
        surname: 'User',
        email: null,
        library_id: null,
        category_id: 'GUEST',
        isGuest: true,
      };

      const newToken = generateToken(guestPatron);
      const expiresAt = getTokenExpiry();

      return successResponse({
        token: newToken,
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
      }, 'Token refreshed');
    }

    // For regular users, fetch fresh patron data
    const patronResult = await getPatronById(decoded.patronId);

    if (!patronResult.success) {
      return errorResponse('Failed to fetch patron details', 500);
    }

    const patron = patronResult.data;

    // Generate new token
    const newToken = generateToken(patron);
    const expiresAt = getTokenExpiry();

    // Update session in database
    try {
      // Delete old session
      await prisma.session.delete({
        where: { token: oldToken },
      });

      // Create new session
      await prisma.session.create({
        data: {
          patronId: patron.patron_id,
          token: newToken,
          expiresAt,
        },
      });
    } catch (dbError) {
      console.warn('Session update failed:', dbError.message);
    }

    return successResponse({
      token: newToken,
      expiresAt: expiresAt.toISOString(),
      user: {
        patronId: patron.patron_id,
        cardNumber: patron.cardnumber,
        firstName: patron.firstname,
        surname: patron.surname,
        email: patron.email,
        libraryId: patron.library_id,
      },
    }, 'Token refreshed');

  } catch (error) {
    console.error('Token refresh error:', error);
    return errorResponse('Failed to refresh token', 500);
  }
}
