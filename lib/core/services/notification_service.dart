import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:campuscast/core/routes/app_router.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Background] Message: ${message.messageId}');
  print('[FCM Background] Title: ${message.notification?.title}');
  print('[FCM Background] Body: ${message.notification?.body}');
  print('[FCM Background] Data: ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get the FCM token
        _fcmToken = await _messaging.getToken();
        print('[FCM] Token: $_fcmToken');

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          print('[FCM] Token refreshed: $newToken');
          // Update token in Firestore if user is logged in
          _updateTokenInFirestore(newToken);
        });

        // Set up background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background/terminated
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } else {
        print('[FCM] Notification permission denied');
      }
    } catch (e) {
      print('[FCM] Error initializing: $e');
    }
  }

  /// Save FCM token to Firestore user document
  Future<void> saveTokenToFirestore(String userId) async {
    if (_fcmToken == null) {
      print('[FCM] No token to save');
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('[FCM] Token saved to Firestore for user: $userId');
    } catch (e) {
      print('[FCM] Error saving token: $e');
    }
  }

  /// Remove FCM token from Firestore (on logout)
  Future<void> removeTokenFromFirestore(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': null,
        },
        SetOptions(merge: true),
      );
      print('[FCM] Token removed from Firestore');
    } catch (e) {
      print('[FCM] Error removing token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('[FCM Foreground] Message received');
    print('[FCM Foreground] Title: ${message.notification?.title}');
    print('[FCM Foreground] Body: ${message.notification?.body}');
    print('[FCM Foreground] Data: ${message.data}');

    // You can show a local notification here or update UI
    // For now, just logging
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('[FCM Tap] Notification tapped');
    print('[FCM Tap] Data: ${message.data}');

    // Navigate to the appropriate screen based on notification data
    final data = message.data;
    
    if (data.containsKey('type') && data['type'] == 'live_broadcast') {
      final broadcastId = data['broadcastId'];
      final channelName = data['channelName'];
      
      if (broadcastId != null && channelName != null) {
        print('[FCM Tap] Opening live broadcast: $broadcastId');
        
        // Navigate to live player using global navigator key
        if (rootNavigatorKey.currentContext != null) {
          rootNavigatorKey.currentContext!.go(
            AppRoutes.livePlayer,
            extra: {
              'broadcastId': broadcastId,
              'channelName': channelName,
            },
          );
        } else {
          print('[FCM Tap] Navigator context not available');
        }
      }
    }
  }

  /// Update token when it refreshes
  Future<void> _updateTokenInFirestore(String newToken) async {
    // Get current user ID and update
    // This requires auth context, will be called from auth provider
    print('[FCM] Token needs update: $newToken');
  }

  /// Subscribe to a topic (e.g., channel-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      print('[FCM] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      print('[FCM] Error unsubscribing from topic: $e');
    }
  }
}
