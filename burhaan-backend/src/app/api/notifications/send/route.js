/**
 * POST /api/notifications/send
 * Send a push notification (Admin only)
 */

import { requireAuth, errorResponse, successResponse } from '@/lib/auth';
import { validateRequired } from '@/lib/helpers';
import { sendNotification, sendNotificationToMultiple, sendToTopic, isPushConfigured, createLibraryNotification, NotificationTypes } from '@/lib/notifications';
import { prisma } from '@/lib/db';

export async function POST(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  // In production, verify admin role
  const { user } = authResult;

  if (!isPushConfigured()) {
    return errorResponse('Push notifications are not configured', 503);
  }

  try {
    const body = await request.json();

    // Validate required fields
    const validation = validateRequired(body, ['title', 'body']);
    if (!validation.valid) {
      return errorResponse(validation.error, 400);
    }

    const { title, body: messageBody, data, target } = body;

    // Target can be:
    // - { patronId: number } - send to specific patron's devices
    // - { patronIds: number[] } - send to multiple patrons
    // - { topic: string } - send to topic subscribers
    // - { all: true } - send to all registered devices

    const notification = { title, body: messageBody };

    if (target?.patronId) {
      // Send to specific patron
      const tokens = await prisma.pushToken.findMany({
        where: { patronId: target.patronId },
      });

      if (tokens.length === 0) {
        return errorResponse('No registered devices for this patron', 404);
      }

      const tokenStrings = tokens.map(t => t.token);
      const result = await sendNotificationToMultiple(tokenStrings, notification, data);

      // Clean up invalid tokens
      if (result.invalidTokens?.length > 0) {
        for (const token of tokens) {
          if (result.invalidTokens.includes(token.token)) {
            await prisma.pushToken.delete({
              where: {
                patronId_deviceId: {
                  patronId: token.patronId,
                  deviceId: token.deviceId,
                },
              },
            }).catch(() => {});
          }
        }
      }

      return successResponse({
        sent: true,
        successCount: result.successCount,
        failureCount: result.failureCount,
      });

    } else if (target?.patronIds && Array.isArray(target.patronIds)) {
      // Send to multiple patrons
      const tokens = await prisma.pushToken.findMany({
        where: { patronId: { in: target.patronIds } },
      });

      if (tokens.length === 0) {
        return errorResponse('No registered devices for these patrons', 404);
      }

      const tokenStrings = tokens.map(t => t.token);
      const result = await sendNotificationToMultiple(tokenStrings, notification, data);

      return successResponse({
        sent: true,
        successCount: result.successCount,
        failureCount: result.failureCount,
        totalDevices: tokens.length,
      });

    } else if (target?.topic) {
      // Send to topic
      const result = await sendToTopic(target.topic, notification, data);

      if (!result.success) {
        return errorResponse(result.error || 'Failed to send notification', 500);
      }

      return successResponse({
        sent: true,
        topic: target.topic,
        messageId: result.messageId,
      });

    } else if (target?.all) {
      // Send to all devices
      const tokens = await prisma.pushToken.findMany({});

      if (tokens.length === 0) {
        return errorResponse('No registered devices', 404);
      }

      // Send in batches of 500 (FCM limit)
      const batchSize = 500;
      let totalSuccess = 0;
      let totalFailure = 0;

      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);
        const tokenStrings = batch.map(t => t.token);
        const result = await sendNotificationToMultiple(tokenStrings, notification, data);

        totalSuccess += result.successCount || 0;
        totalFailure += result.failureCount || 0;
      }

      return successResponse({
        sent: true,
        successCount: totalSuccess,
        failureCount: totalFailure,
        totalDevices: tokens.length,
      });

    } else {
      return errorResponse('Invalid target. Specify patronId, patronIds, topic, or all', 400);
    }

  } catch (error) {
    console.error('Send notification error:', error);
    return errorResponse('Internal server error', 500);
  }
}

/**
 * GET /api/notifications/send
 * Get notification types and templates
 */
export async function GET(request) {
  // Check authentication
  const authResult = requireAuth(request);
  if (!authResult.authorized) {
    return authResult.response;
  }

  return successResponse({
    configured: isPushConfigured(),
    types: Object.values(NotificationTypes),
    templates: [
      {
        type: NotificationTypes.HOLD_READY,
        description: 'Notify when a hold is ready for pickup',
        requiredData: ['bookTitle', 'library', 'holdId', 'biblioId'],
      },
      {
        type: NotificationTypes.DUE_SOON,
        description: 'Notify when a book is due soon',
        requiredData: ['bookTitle', 'daysUntilDue', 'checkoutId', 'biblioId'],
      },
      {
        type: NotificationTypes.OVERDUE,
        description: 'Notify when a book is overdue',
        requiredData: ['bookTitle', 'checkoutId', 'biblioId'],
      },
      {
        type: NotificationTypes.NEW_BOOK,
        description: 'Notify about a new book',
        requiredData: ['bookTitle', 'author', 'biblioId'],
      },
      {
        type: NotificationTypes.NEW_VIDEO,
        description: 'Notify about a new video',
        requiredData: ['title', 'videoId'],
      },
    ],
  });
}
