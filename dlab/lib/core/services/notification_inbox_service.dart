import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationInboxItem {
  const NotificationInboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.isRead,
    required this.data,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final Map<String, dynamic> data;

  NotificationInboxItem copyWith({
    bool? isRead,
  }) {
    return NotificationInboxItem(
      id: id,
      title: title,
      body: body,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationInboxItem.fromMap(Map<String, dynamic> map) {
    return NotificationInboxItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      receivedAt:
          DateTime.tryParse(map['receivedAt'] as String? ?? '') ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      data: (map['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class NotificationInboxService {
  NotificationInboxService._();

  static const _prefsKey = 'local_notification_inbox_v1';
  static const _maxItems = 200;

  static Future<List<NotificationInboxItem>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];

    final items = raw
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .map(NotificationInboxItem.fromMap)
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    return items;
  }

  static Future<void> saveFromRemoteMessage(
    RemoteMessage message, {
    bool isRead = false,
  }) async {
    final title = message.notification?.title ??
      message.data['title']?.toString() ??
      message.data['notificationTitle']?.toString() ??
      'Notification';
    final body = message.notification?.body ??
      message.data['body']?.toString() ??
      message.data['message']?.toString() ??
      message.data['description']?.toString() ??
      '';

    if (title.trim().isEmpty && body.trim().isEmpty) {
      return;
    }

    final payloadId = message.messageId;
    final id = (payloadId != null && payloadId.trim().isNotEmpty)
        ? payloadId
        : '${DateTime.now().microsecondsSinceEpoch}_${title.hashCode}_${body.hashCode}';

    final receivedAt = message.sentTime ?? DateTime.now();

    final item = NotificationInboxItem(
      id: id,
      title: title,
      body: body,
      receivedAt: receivedAt,
      isRead: isRead,
      data: Map<String, dynamic>.from(message.data),
    );

    final existing = await getNotifications();
    final filtered = existing.where((entry) => entry.id != id).toList();
    final updated = [item, ...filtered];

    if (updated.length > _maxItems) {
      updated.removeRange(_maxItems, updated.length);
    }

    await _persist(updated);
  }

  static Future<void> markAsRead(String id) async {
    final existing = await getNotifications();
    var changed = false;

    final updated = existing.map((item) {
      if (item.id == id && !item.isRead) {
        changed = true;
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    if (changed) {
      await _persist(updated);
    }
  }

  static Future<void> markAllAsRead() async {
    final existing = await getNotifications();
    if (existing.every((item) => item.isRead)) {
      return;
    }

    final updated = existing.map((item) => item.copyWith(isRead: true)).toList();
    await _persist(updated);
  }

  static Future<void> _persist(List<NotificationInboxItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_prefsKey, encoded);
  }
}
