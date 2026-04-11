import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../firebase_options.dart';
import 'notification_inbox_service.dart';

import '../env/env_selector.dart';

const _defaultBroadcastTopic = 'all_users';
const _userTopicPrefsKey = 'fcm_user_topic';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await NotificationInboxService.saveFromRemoteMessage(message);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await requestPermissions();

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[push] foreground message: ${message.messageId}');
        unawaited(NotificationInboxService.saveFromRemoteMessage(message));
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[push] opened from notification: ${message.messageId}');
        unawaited(NotificationInboxService.saveFromRemoteMessage(message));
      });

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        unawaited(NotificationInboxService.saveFromRemoteMessage(initialMessage));
      }

      _initialized = true;
    } catch (err) {
      debugPrint('[push] Firebase init skipped: $err');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  Future<String?> getFcmToken() async {
    await initialize();
    if (!_initialized) return null;
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('[push] FCM token: $token');
    return token;
  }

  Future<void> syncTopicSubscriptionsForCurrentUser() async {
    await initialize();
    if (!_initialized) return;

    if (kIsWeb) return;

    await FirebaseMessaging.instance.subscribeToTopic(_defaultBroadcastTopic);
    debugPrint('[push] subscribed broadcast topic: $_defaultBroadcastTopic');
    await getFcmToken();

    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('[push] no access token; clearing private topic subscription');
      await clearUserTopicSubscription();
      return;
    }

    final topicInfo = await _fetchUserTopic(accessToken);
    if (topicInfo == null) {
      debugPrint('[push] user topic API unavailable, broadcast topic subscription kept');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final previousUserTopic = prefs.getString(_userTopicPrefsKey);

    final userTopic = topicInfo['userTopic'];
    final broadcastTopic = topicInfo['broadcastTopic'] ?? _defaultBroadcastTopic;

    await FirebaseMessaging.instance.subscribeToTopic(broadcastTopic);
    debugPrint('[push] subscribed broadcast topic from API: $broadcastTopic');

    if (userTopic != null && userTopic.isNotEmpty) {
      if (previousUserTopic != null && previousUserTopic != userTopic) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(previousUserTopic);
        debugPrint('[push] unsubscribed previous user topic: $previousUserTopic');
      }

      await FirebaseMessaging.instance.subscribeToTopic(userTopic);
      await prefs.setString(_userTopicPrefsKey, userTopic);
      debugPrint('[push] subscribed user topic: $userTopic');
    }
  }

  Future<void> clearUserTopicSubscription() async {
    await initialize();
    if (!_initialized) return;

    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final existingTopic = prefs.getString(_userTopicPrefsKey);

    if (existingTopic != null && existingTopic.isNotEmpty) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(existingTopic);
      await prefs.remove(_userTopicPrefsKey);
      debugPrint('[push] cleared user topic: $existingTopic');
    }
  }

  Future<Map<String, String>?> _fetchUserTopic(String accessToken) async {
    final baseUrl = EnvSelector.current().baseUrl;
    final uri = Uri.parse('$baseUrl/notifications/topic');

    final result = await _plainHttpPost(uri, accessToken);
    if (result == null) return null;

    return {
      'userTopic': (result['userTopic'] ?? '').toString(),
      'broadcastTopic': (result['broadcastTopic'] ?? _defaultBroadcastTopic).toString(),
    };
  }

  Future<Map<String, dynamic>?> _plainHttpPost(Uri uri, String accessToken) async {
    try {
      final response = await http.post(uri,
          headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
          body: '{}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[push] topic API failed: ${response.statusCode} ${response.body}');
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (err) {
      debugPrint('[push] failed to fetch topic info: $err');
      return null;
    }
  }
}
