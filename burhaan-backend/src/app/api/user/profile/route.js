/**
 * GET /api/user/profile
 * Get the current user's profile information
 *
 * PUT /api/user/profile
 * Update user preferences (language, theme, etc.)
 */

import { getPatronById } from '@/lib/koha';
import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { formatPatronResponse } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  try {
    // For guest users, return limited profile
    if (user.isGuest) {
      return successResponse({
        patron: {
          patronId: 0,
          cardNumber: 'GUEST',
          firstName: 'Guest',
          surname: 'User',
          fullName: 'Guest User',
          email: null,
          isGuest: true,
        },
        preferences: {
          language: 'en',
          theme: 'light',
          notificationsEnabled: false,
          homeLibraryId: null,
        },
      });
    }

    // Fetch patron details from Koha
    const patronResult = await getPatronById(user.patronId);

    if (!patronResult.success) {
      return errorResponse('Failed to fetch profile', 500);
    }

    // Get user preferences from database
    let preferences = {
      language: 'en',
      theme: 'light',
      notificationsEnabled: true,
      homeLibraryId: null,
    };

    try {
      const dbPreferences = await prisma.userPreference.findUnique({
        where: { patronId: user.patronId },
      });

      if (dbPreferences) {
        preferences = {
          language: dbPreferences.language,
          theme: dbPreferences.theme,
          notificationsEnabled: dbPreferences.notificationsEnabled,
          homeLibraryId: dbPreferences.homeLibraryId,
        };
      }
    } catch (dbError) {
      console.warn('Failed to fetch preferences:', dbError.message);
    }

    return successResponse({
      patron: formatPatronResponse(patronResult.data),
      preferences,
    });

  } catch (error) {
    console.error('Profile fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function PUT(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot update preferences', 403);
  }

  try {
    const body = await request.json();
    const { language, theme, notificationsEnabled, homeLibraryId } = body;

    // Validate language
    const validLanguages = ['en', 'ar', 'ur'];
    if (language && !validLanguages.includes(language)) {
      return errorResponse('Invalid language. Must be one of: en, ar, ur', 400);
    }

    // Validate theme
    const validThemes = ['light', 'dark'];
    if (theme && !validThemes.includes(theme)) {
      return errorResponse('Invalid theme. Must be one of: light, dark', 400);
    }

    // Update preferences in database
    const updatedPreferences = await prisma.userPreference.upsert({
      where: { patronId: user.patronId },
      update: {
        ...(language && { language }),
        ...(theme && { theme }),
        ...(typeof notificationsEnabled === 'boolean' && { notificationsEnabled }),
        ...(homeLibraryId !== undefined && { homeLibraryId }),
      },
      create: {
        patronId: user.patronId,
        language: language || 'en',
        theme: theme || 'light',
        notificationsEnabled: notificationsEnabled ?? true,
        homeLibraryId: homeLibraryId || null,
      },
    });

    return successResponse({
      preferences: {
        language: updatedPreferences.language,
        theme: updatedPreferences.theme,
        notificationsEnabled: updatedPreferences.notificationsEnabled,
        homeLibraryId: updatedPreferences.homeLibraryId,
      },
    }, 'Preferences updated successfully');

  } catch (error) {
    console.error('Profile update error:', error);
    return errorResponse('Internal server error', 500);
  }
}
