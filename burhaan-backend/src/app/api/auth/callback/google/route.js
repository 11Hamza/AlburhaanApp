/**
 * GET /api/auth/callback/google
 * Handle Google OAuth2 callback
 */

import { exchangeGoogleCode, getGoogleUserProfile } from '@/lib/oauth';
import { generateToken, getTokenExpiry } from '@/lib/auth';
import { kohaRequest } from '@/lib/koha';
import { prisma } from '@/lib/db';

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');

    // Parse state to get return URL
    let returnUrl = '/';
    if (state) {
      try {
        const stateData = JSON.parse(Buffer.from(state, 'base64').toString());
        returnUrl = stateData.returnUrl || '/';
      } catch (e) {
        console.warn('Failed to parse state:', e);
      }
    }

    // Handle OAuth errors
    if (error) {
      const errorUrl = new URL(returnUrl, request.url);
      errorUrl.searchParams.set('error', error);
      errorUrl.searchParams.set('provider', 'google');
      return Response.redirect(errorUrl.toString());
    }

    if (!code) {
      const errorUrl = new URL(returnUrl, request.url);
      errorUrl.searchParams.set('error', 'no_code');
      return Response.redirect(errorUrl.toString());
    }

    // Exchange code for tokens
    const tokenResult = await exchangeGoogleCode(code);
    if (!tokenResult.success) {
      const errorUrl = new URL(returnUrl, request.url);
      errorUrl.searchParams.set('error', 'token_exchange_failed');
      return Response.redirect(errorUrl.toString());
    }

    // Get user profile
    const profileResult = await getGoogleUserProfile(tokenResult.data.access_token);
    if (!profileResult.success) {
      const errorUrl = new URL(returnUrl, request.url);
      errorUrl.searchParams.set('error', 'profile_fetch_failed');
      return Response.redirect(errorUrl.toString());
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
        // No existing patron - redirect to registration
        const registerUrl = new URL('/register', request.url);
        registerUrl.searchParams.set('provider', 'google');
        registerUrl.searchParams.set('email', profile.email);
        registerUrl.searchParams.set('firstName', profile.firstName);
        registerUrl.searchParams.set('lastName', profile.lastName);
        registerUrl.searchParams.set('providerId', profile.providerAccountId);
        return Response.redirect(registerUrl.toString());
      }
    }

    if (!patron) {
      const errorUrl = new URL(returnUrl, request.url);
      errorUrl.searchParams.set('error', 'patron_not_found');
      return Response.redirect(errorUrl.toString());
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

    // Redirect with token (for web apps)
    const successUrl = new URL(returnUrl, request.url);
    successUrl.searchParams.set('token', token);
    successUrl.searchParams.set('provider', 'google');
    return Response.redirect(successUrl.toString());

  } catch (error) {
    console.error('Google callback error:', error);
    return Response.redirect('/?error=callback_failed&provider=google');
  }
}
