import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'api_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Lazy getter - only access after Firebase is initialized
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and notification handling
  Future<void> initialize() async {
    try {
      // Initialize Firebase with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Get FCM token
      await _getToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('NotificationService initialized with token: $_fcmToken');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('Notification permission: ${settings.authorizationStatus}');
    return authorized;
  }

  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    _fcmToken = token;
    debugPrint('FCM token refreshed: $token');
    // Re-register with backend
    registerToken();
  }

  /// Handle foreground messages
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');

    // You can show a local notification here if needed
    // For now, we'll just log it
    final notification = message.notification;
    if (notification != null) {
      debugPrint('Title: ${notification.title}');
      debugPrint('Body: ${notification.body}');
    }
  }

  /// Handle notification tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _handleNotificationTap(message);
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    debugPrint('Handling notification tap - type: $type, data: $data');

    // Navigation will be handled by the app based on type
    // Types: hold_ready, due_soon, overdue, new_book, new_video
    // This would typically update a stream or callback that the app listens to
  }

  /// Register FCM token with backend
  Future<bool> registerToken() async {
    if (_fcmToken == null) {
      await _getToken();
    }

    if (_fcmToken == null) {
      debugPrint('No FCM token available');
      return false;
    }

    try {
      final deviceId = await _getDeviceId();
      final platform = _getPlatform();

      final response = await _api.post<Map<String, dynamic>>(
        '/api/notifications/token',
        body: {
          'token': _fcmToken,
          'deviceId': deviceId,
          'platform': platform,
        },
      );

      if (response.success) {
        debugPrint('FCM token registered successfully');
        return true;
      } else {
        debugPrint('Failed to register FCM token: ${response.error}');
        return false;
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token from backend
  Future<bool> unregisterToken() async {
    try {
      final deviceId = await _getDeviceId();

      final response = await _api.delete<Map<String, dynamic>>(
        '/api/notifications/token',
      );

      return response.success;
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
      return false;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic: $e');
    }
  }

  /// Get device ID for token registration
  Future<String> _getDeviceId() async {
    // In a real app, you'd use device_info_plus to get a unique device ID
    // For now, we'll use a simple hash of platform + timestamp
    return '${_getPlatform()}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
