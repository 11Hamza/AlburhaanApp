/**
 * Push Notification Service
 * Handles sending push notifications via Firebase Cloud Messaging (FCM)
 */

// FCM Configuration
const FCM_SERVER_KEY = process.env.FCM_SERVER_KEY;
const FCM_API_URL = 'https://fcm.googleapis.com/fcm/send';

/**
 * Send push notification to a single device
 */
export async function sendNotification(token, notification, data = {}) {
  if (!FCM_SERVER_KEY) {
    console.warn('FCM_SERVER_KEY not configured');
    return { success: false, error: 'Push notifications not configured' };
  }

  try {
    const response = await fetch(FCM_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: notification.title,
          body: notification.body,
          icon: notification.icon || '/icon.png',
          click_action: notification.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
          sound: notification.sound || 'default',
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        priority: 'high',
      }),
    });

    const result = await response.json();

    if (result.success === 1) {
      return { success: true, messageId: result.results?.[0]?.message_id };
    }

    // Check for invalid token
    if (result.results?.[0]?.error === 'NotRegistered') {
      return { success: false, error: 'Token not registered', invalidToken: true };
    }

    return { success: false, error: result.results?.[0]?.error || 'Failed to send' };
  } catch (error) {
    console.error('FCM send error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Send push notification to multiple devices
 */
export async function sendNotificationToMultiple(tokens, notification, data = {}) {
  if (!FCM_SERVER_KEY) {
    console.warn('FCM_SERVER_KEY not configured');
    return { success: false, error: 'Push notifications not configured' };
  }

  if (!tokens || tokens.length === 0) {
    return { success: false, error: 'No tokens provided' };
  }

  try {
    const response = await fetch(FCM_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        registration_ids: tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          icon: notification.icon || '/icon.png',
          click_action: notification.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
          sound: notification.sound || 'default',
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        priority: 'high',
      }),
    });

    const result = await response.json();

    // Collect invalid tokens
    const invalidTokens = [];
    result.results?.forEach((res, index) => {
      if (res.error === 'NotRegistered' || res.error === 'InvalidRegistration') {
        invalidTokens.push(tokens[index]);
      }
    });

    return {
      success: true,
      successCount: result.success || 0,
      failureCount: result.failure || 0,
      invalidTokens,
    };
  } catch (error) {
    console.error('FCM batch send error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Send notification to a topic
 */
export async function sendToTopic(topic, notification, data = {}) {
  if (!FCM_SERVER_KEY) {
    console.warn('FCM_SERVER_KEY not configured');
    return { success: false, error: 'Push notifications not configured' };
  }

  try {
    const response = await fetch(FCM_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: `/topics/${topic}`,
        notification: {
          title: notification.title,
          body: notification.body,
          icon: notification.icon || '/icon.png',
          click_action: notification.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
          sound: notification.sound || 'default',
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        priority: 'high',
      }),
    });

    const result = await response.json();

    if (result.message_id) {
      return { success: true, messageId: result.message_id };
    }

    return { success: false, error: result.error || 'Failed to send' };
  } catch (error) {
    console.error('FCM topic send error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Notification types for the library app
 */
export const NotificationTypes = {
  HOLD_READY: 'hold_ready',
  HOLD_EXPIRED: 'hold_expired',
  DUE_SOON: 'due_soon',
  OVERDUE: 'overdue',
  NEW_BOOK: 'new_book',
  NEW_VIDEO: 'new_video',
  ACCOUNT_UPDATE: 'account_update',
  GENERAL: 'general',
};

/**
 * Create notification payload for common library events
 */
export function createLibraryNotification(type, data = {}) {
  switch (type) {
    case NotificationTypes.HOLD_READY:
      return {
        notification: {
          title: 'Your Hold is Ready!',
          body: `"${data.bookTitle}" is ready for pickup at ${data.library}`,
        },
        data: {
          type,
          holdId: data.holdId?.toString(),
          biblioId: data.biblioId?.toString(),
        },
      };

    case NotificationTypes.HOLD_EXPIRED:
      return {
        notification: {
          title: 'Hold Expired',
          body: `Your hold for "${data.bookTitle}" has expired`,
        },
        data: {
          type,
          holdId: data.holdId?.toString(),
          biblioId: data.biblioId?.toString(),
        },
      };

    case NotificationTypes.DUE_SOON:
      return {
        notification: {
          title: 'Book Due Soon',
          body: `"${data.bookTitle}" is due in ${data.daysUntilDue} days`,
        },
        data: {
          type,
          checkoutId: data.checkoutId?.toString(),
          biblioId: data.biblioId?.toString(),
        },
      };

    case NotificationTypes.OVERDUE:
      return {
        notification: {
          title: 'Book Overdue',
          body: `"${data.bookTitle}" is overdue. Please return it soon.`,
        },
        data: {
          type,
          checkoutId: data.checkoutId?.toString(),
          biblioId: data.biblioId?.toString(),
        },
      };

    case NotificationTypes.NEW_BOOK:
      return {
        notification: {
          title: 'New Book Added',
          body: `Check out "${data.bookTitle}" by ${data.author}`,
        },
        data: {
          type,
          biblioId: data.biblioId?.toString(),
        },
      };

    case NotificationTypes.NEW_VIDEO:
      return {
        notification: {
          title: 'New Video Available',
          body: `Watch "${data.title}" now`,
        },
        data: {
          type,
          videoId: data.videoId?.toString(),
        },
      };

    default:
      return {
        notification: {
          title: data.title || 'Al-Burhaan Library',
          body: data.body || 'You have a new notification',
        },
        data: {
          type: NotificationTypes.GENERAL,
          ...data,
        },
      };
  }
}

/**
 * Check if push notifications are configured
 */
export function isPushConfigured() {
  return !!FCM_SERVER_KEY;
}
