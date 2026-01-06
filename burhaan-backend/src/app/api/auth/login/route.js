/**
 * POST /api/auth/login
 * Login with library card number and password
 */

import { validateCredentials, getPatronByCardNumber } from '@/lib/koha';
import { generateToken, errorResponse, successResponse, getTokenExpiry } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function POST(request) {
  try {
    const body = await request.json();
    const { cardNumber, password } = body;

    // Validate input
    if (!cardNumber || !password) {
      return errorResponse('Card number and password are required', 400);
    }

    // Validate credentials against Koha
    const isValid = await validateCredentials(cardNumber, password);

    if (!isValid) {
      return errorResponse('Invalid card number or password', 401, 'INVALID_CREDENTIALS');
    }

    // Get patron details from Koha
    const patronResult = await getPatronByCardNumber(cardNumber);

    if (!patronResult.success) {
      return errorResponse('Failed to fetch patron details', 500);
    }

    const patron = patronResult.data;

    // Generate JWT token
    const token = generateToken(patron);
    const expiresAt = getTokenExpiry();

    // Store session in database
    try {
      await prisma.session.create({
        data: {
          patronId: patron.patron_id,
          token,
          expiresAt,
        },
      });
    } catch (dbError) {
      console.warn('Session storage failed (continuing without persistence):', dbError.message);
    }

    return successResponse({
      token,
      expiresAt: expiresAt.toISOString(),
      user: {
        patronId: patron.patron_id,
        cardNumber: patron.cardnumber,
        firstName: patron.firstname,
        surname: patron.surname,
        email: patron.email,
        libraryId: patron.library_id,
      },
    }, 'Login successful');

  } catch (error) {
    console.error('Login error:', error);
    return errorResponse('Internal server error', 500);
  }
}
