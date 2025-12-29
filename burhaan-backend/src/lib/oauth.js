/**
 * OAuth Utilities
 * Handles OAuth2 authentication with Google and Microsoft
 */

// OAuth Configuration from environment
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const MICROSOFT_CLIENT_ID = process.env.MICROSOFT_CLIENT_ID;
const MICROSOFT_CLIENT_SECRET = process.env.MICROSOFT_CLIENT_SECRET;
const OAUTH_REDIRECT_URI = process.env.OAUTH_REDIRECT_URI || 'http://localhost:3000/api/auth/callback';

/**
 * Generate Google OAuth2 authorization URL
 */
export function getGoogleAuthUrl(state = null) {
  const params = new URLSearchParams({
    client_id: GOOGLE_CLIENT_ID,
    redirect_uri: `${OAUTH_REDIRECT_URI}/google`,
    response_type: 'code',
    scope: 'openid email profile',
    access_type: 'offline',
    prompt: 'consent',
  });

  if (state) {
    params.append('state', state);
  }

  return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
}

/**
 * Generate Microsoft OAuth2 authorization URL
 */
export function getMicrosoftAuthUrl(state = null) {
  const params = new URLSearchParams({
    client_id: MICROSOFT_CLIENT_ID,
    redirect_uri: `${OAUTH_REDIRECT_URI}/microsoft`,
    response_type: 'code',
    scope: 'openid email profile User.Read',
    response_mode: 'query',
  });

  if (state) {
    params.append('state', state);
  }

  return `https://login.microsoftonline.com/common/oauth2/v2.0/authorize?${params.toString()}`;
}

/**
 * Exchange Google authorization code for tokens
 */
export async function exchangeGoogleCode(code) {
  try {
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        code,
        client_id: GOOGLE_CLIENT_ID,
        client_secret: GOOGLE_CLIENT_SECRET,
        redirect_uri: `${OAUTH_REDIRECT_URI}/google`,
        grant_type: 'authorization_code',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('Google token exchange error:', error);
      return { success: false, error: 'Failed to exchange code' };
    }

    const tokens = await response.json();
    return { success: true, data: tokens };
  } catch (error) {
    console.error('Google token exchange error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Exchange Microsoft authorization code for tokens
 */
export async function exchangeMicrosoftCode(code) {
  try {
    const response = await fetch('https://login.microsoftonline.com/common/oauth2/v2.0/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        code,
        client_id: MICROSOFT_CLIENT_ID,
        client_secret: MICROSOFT_CLIENT_SECRET,
        redirect_uri: `${OAUTH_REDIRECT_URI}/microsoft`,
        grant_type: 'authorization_code',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('Microsoft token exchange error:', error);
      return { success: false, error: 'Failed to exchange code' };
    }

    const tokens = await response.json();
    return { success: true, data: tokens };
  } catch (error) {
    console.error('Microsoft token exchange error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get Google user profile from access token
 */
export async function getGoogleUserProfile(accessToken) {
  try {
    const response = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      return { success: false, error: 'Failed to fetch user profile' };
    }

    const profile = await response.json();
    return {
      success: true,
      data: {
        providerAccountId: profile.id,
        email: profile.email,
        emailVerified: profile.verified_email,
        firstName: profile.given_name || '',
        lastName: profile.family_name || '',
        fullName: profile.name || '',
        picture: profile.picture || null,
        provider: 'google',
      },
    };
  } catch (error) {
    console.error('Google profile fetch error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get Microsoft user profile from access token
 */
export async function getMicrosoftUserProfile(accessToken) {
  try {
    const response = await fetch('https://graph.microsoft.com/v1.0/me', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      return { success: false, error: 'Failed to fetch user profile' };
    }

    const profile = await response.json();
    return {
      success: true,
      data: {
        providerAccountId: profile.id,
        email: profile.mail || profile.userPrincipalName,
        emailVerified: true, // Microsoft accounts are verified
        firstName: profile.givenName || '',
        lastName: profile.surname || '',
        fullName: profile.displayName || '',
        picture: null, // Would need separate call to get photo
        provider: 'microsoft',
      },
    };
  } catch (error) {
    console.error('Microsoft profile fetch error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Validate ID token (for mobile apps using Sign-In SDKs)
 */
export async function validateGoogleIdToken(idToken) {
  try {
    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);

    if (!response.ok) {
      return { success: false, error: 'Invalid token' };
    }

    const payload = await response.json();

    // Log the audience for debugging
    console.log('Token audience (aud):', payload.aud);
    console.log('Expected GOOGLE_CLIENT_ID:', GOOGLE_CLIENT_ID);

    // Verify the token is for our app
    if (payload.aud !== GOOGLE_CLIENT_ID) {
      console.error(`Client ID mismatch! Token aud: ${payload.aud}, Expected: ${GOOGLE_CLIENT_ID}`);
      return { success: false, error: 'Token not issued for this app' };
    }

    return {
      success: true,
      data: {
        providerAccountId: payload.sub,
        email: payload.email,
        emailVerified: payload.email_verified === 'true',
        firstName: payload.given_name || '',
        lastName: payload.family_name || '',
        fullName: payload.name || '',
        picture: payload.picture || null,
        provider: 'google',
      },
    };
  } catch (error) {
    console.error('Google ID token validation error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Check if OAuth is configured
 */
export function isGoogleConfigured() {
  return !!(GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET);
}

export function isMicrosoftConfigured() {
  return !!(MICROSOFT_CLIENT_ID && MICROSOFT_CLIENT_SECRET);
}

export {
  GOOGLE_CLIENT_ID,
  MICROSOFT_CLIENT_ID,
  OAUTH_REDIRECT_URI,
};
