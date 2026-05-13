import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handles Firebase Cloud Messaging (push notifications).
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission (iOS / Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token (save to Firestore if you want server-side pushes)
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      // You can show a local notification here using flutter_local_notifications
    });

    // Handle background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.data}');
      // Navigate to relevant post using message.data['postId']
    });
  }

  /// Subscribe to a topic (e.g. 'ghana_posts')
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}
