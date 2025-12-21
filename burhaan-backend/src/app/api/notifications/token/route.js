/**
 * POST /api/notifications/token
 * Register a device push token
 *
 * DELETE /api/notifications/token
 * Unregister a device push token
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { validateRequired } from '@/lib/helpers';
import { prisma } from '@/lib/db';

export async function POST(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return errorResponse('Guests cannot register for notifications', 403);
  }

  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['token', 'deviceId']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const { token, deviceId, platform, deviceName } = body;

    // Validate platform
    const validPlatforms = ['ios', 'android', 'web'];
    if (platform && !validPlatforms.includes(platform.toLowerCase())) {
      return errorResponse(`Invalid platform. Must be one of: ${validPlatforms.join(', ')}`, 400);
    }

    // Upsert the push token
    const pushToken = await prisma.pushToken.upsert({
      where: {
        patronId_deviceId: {
          patronId: user.patronId,
          deviceId,
        },
      },
      update: {
        token,
        platform: platform?.toLowerCase() || 'unknown',
        deviceName: deviceName || null,
        lastUsed: new Date(),
      },
      create: {
        patronId: user.patronId,
        deviceId,
        token,
        platform: platform?.toLowerCase() || 'unknown',
        deviceName: deviceName || null,
        lastUsed: new Date(),
      },
    });

    return successResponse({
      registered: true,
      deviceId: pushToken.deviceId,
    }, 'Push token registered');

  } catch (error) {
    console.error('Push token registration error:', error);
    return errorResponse('Internal server error', 500);
  }
}

export async function DELETE(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  try {
    const body = await request.json();
    const { deviceId } = body;

    if (!deviceId) {
      return errorResponse('deviceId is required', 400);
    }

    // Delete the push token
    await prisma.pushToken.delete({
      where: {
        patronId_deviceId: {
          patronId: user.patronId,
          deviceId,
        },
      },
    });

    return successResponse({
      unregistered: true,
    }, 'Push token unregistered');

  } catch (error) {
    console.error('Push token deletion error:', error);
    return errorResponse('Internal server error', 500);
  }
}

/**
 * GET /api/notifications/token
 * Get all registered devices for the current user
 */
export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  const { user } = authResult;

  if (user.isGuest) {
    return successResponse({ devices: [] });
  }

  try {
    const tokens = await prisma.pushToken.findMany({
      where: { patronId: user.patronId },
    });

    return successResponse({
      devices: tokens.map(t => ({
        deviceId: t.deviceId,
        platform: t.platform,
        deviceName: t.deviceName,
        registeredAt: t.createdAt,
        lastUsed: t.lastUsed,
      })),
    });

  } catch (error) {
    console.error('Push tokens fetch error:', error);
    return errorResponse('Internal server error', 500);
  }
}
