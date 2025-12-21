/**
 * GET /api/auth/sso/google
 * Initiate Google OAuth2 login flow
 *
 * POST /api/auth/sso/google
 * Mobile login with Google ID token
 */

import { getGoogleAuthUrl, validateGoogleIdToken, isGoogleConfigured } from '@/lib/oauth';
import { generateToken, errorResponse, successResponse, getTokenExpiry } from '@/lib/auth';
import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';

export async function GET(request) {
  if (!isGoogleConfigured()) {
    return errorResponse('Google login is not configured', 503);
  }

  try {
    const { searchParams } = new URL(request.url);
    const returnUrl = searchParams.get('returnUrl') || '/';

    // Generate state with return URL
    const state = Buffer.from(JSON.stringify({ returnUrl })).toString('base64');

    const authUrl = getGoogleAuthUrl(state);

    // Return the URL for the client to redirect to
    return successResponse({
      authUrl,
      provider: 'google',
    });
  } catch (error) {
    console.error('Google SSO init error:', error);
    return errorResponse('Failed to initiate Google login', 500);
  }
}

/**
 * POST - Handle mobile app login with Google ID token
 */
export async function POST(request) {
  if (!isGoogleConfigured()) {
    return errorResponse('Google login is not configured', 503);
  }

  try {
    const body = await request.json();
    const { idToken } = body;

    if (!idToken) {
      return errorResponse('ID token is required', 400);
    }

    // Validate the ID token
    const profileResult = await validateGoogleIdToken(idToken);

    if (!profileResult.success) {
      return errorResponse(profileResult.error || 'Invalid token', 401);
    }

    const profile = profileResult.data;

    // Check if we have an existing SSO account
    let ssoAccount = await prisma.ssoAccount.findUnique({
      where: {
        provider_providerAccountId: {
          provider: 'google',
          providerAccountId: profile.providerAccountId,
        },
      },
    });

    let patron = null;

    if (ssoAccount) {
      // Existing SSO account - fetch patron
      const patronResult = await kohaRequest(`/patrons/${ssoAccount.patronId}`);
      if (patronResult.success) {
        patron = patronResult.data;
      }
    } else {
      // No SSO account - try to find patron by email
      const patronQuery = JSON.stringify({ email: profile.email });
      const searchResult = await kohaRequest(`/patrons?q=${encodeURIComponent(patronQuery)}`);

      if (searchResult.success && searchResult.data && searchResult.data.length > 0) {
        patron = searchResult.data[0];

        // Create SSO link
        ssoAccount = await prisma.ssoAccount.create({
          data: {
            provider: 'google',
            providerAccountId: profile.providerAccountId,
            email: profile.email,
            patronId: patron.patron_id,
            firstName: profile.firstName,
            lastName: profile.lastName,
            picture: profile.picture,
          },
        });
      } else {
        // No existing patron - return profile for registration
        return successResponse({
          needsRegistration: true,
          profile: {
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName,
            picture: profile.picture,
            provider: 'google',
            providerAccountId: profile.providerAccountId,
          },
        }, 'Account not found. Please register.');
      }
    }

    if (!patron) {
      return errorResponse('Unable to fetch patron account', 500);
    }

    // Generate JWT token
    const token = generateToken(patron);
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
      console.warn('Session storage failed:', dbError.message);
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
      provider: 'google',
    }, 'Login successful');

  } catch (error) {
    console.error('Google SSO error:', error);
    return errorResponse('Google login failed', 500);
  }
}
