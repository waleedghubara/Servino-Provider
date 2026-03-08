// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../api/end_point.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

  Future<void> initNotifications() async {
    // 1. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    // debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Setup Local Notifications (for Foreground)
      await _setupLocalNotifications();

      // 3. Setup Handlers
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // debugPrint('Got a message whilst in the foreground!');
        // debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          // debugPrint(
          //   'Message also contained a notification: ${message.notification}',
          // );
          _showForegroundNotification(message);
        }
      });

      // Background Message Tapped Handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // debugPrint('A new onMessageOpenedApp event was published!');
        // Navigation logic can be handled here or via a stream
      });
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS settings if needed (requires permission prompt mostly handled by Firebase)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        // debugPrint('Local Notification tapped: ${response.payload}');
      },
    );

    // Create channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Use local notifications if notification body exists
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(presentSound: true),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      // debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      // debugPrint("Failed to get FCM token: $e");
      return null;
    }
  }

  Future<void> saveTokenToFirestore(String userId) async {
    String? token = await getFCMToken();
    if (token != null) {
      try {
        // 1. Save to Firestore (keep existing logic)
        await _firestore.collection('users').doc(userId).set({
          'fcm_token': token,
          'last_active': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // debugPrint("Token saved to Firestore for user $userId");

        // 2. Save to MySQL Backend
        await _saveTokenToBackend(userId, token);
      } catch (e) {
        // debugPrint("Error saving token: $e");
      }
    }
  }

  Future<void> _saveTokenToBackend(String userId, String token) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '${EndPoint.baseUrl}${EndPoint.updateFcmToken}',
        data: {
          'user_id': userId,
          'token': token,
          'type': 'provider', // Since this is the Provider App
        },
      );
      // debugPrint("Token saved to Backend: ${response.data}");
    } catch (e) {
      // debugPrint("Error saving token to Backend: $e");
    }
  }

  // Subscribe to topics if needed
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
