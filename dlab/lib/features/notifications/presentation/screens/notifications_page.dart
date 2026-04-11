import 'package:flutter/material.dart';

import '../../../../core/services/notification_inbox_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationInboxItem> _notifications = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final entries = await NotificationInboxService.getNotifications();
    if (!mounted) {
      return;
    }
    setState(() {
      _notifications = entries;
      _isLoading = false;
    });
  }

  Future<void> _markItemRead(NotificationInboxItem item) async {
    if (item.isRead) {
      return;
    }
    await NotificationInboxService.markAsRead(item.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _notifications = _notifications
          .map((entry) => entry.id == item.id ? entry.copyWith(isRead: true) : entry)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _notifications.where((item) => _isSameDate(item.receivedAt, now));
    final others = _notifications.where((item) => !_isSameDate(item.receivedAt, now));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              child: RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    if (_notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _buildSection(
                        title: 'Today',
                        items: today.toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Others',
                        items: others.toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<NotificationInboxItem> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        ..._withSpacing(
          items.map(_buildNotificationTile).toList(),
          const SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationInboxItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _markItemRead(item),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Text(
                              _formatTime(item.receivedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF111827),
                                height: 1.0,
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1B4965),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatTime(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24 && _isSameDate(now, value)) {
      return '${difference.inHours}h ago';
    }

    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = monthNames[value.month - 1];
    return '$month ${value.day}, ${value.year}';
  }

  static List<Widget> _withSpacing(List<Widget> children, Widget spacer) {
    if (children.isEmpty) {
      return const [];
    }

    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      result.add(children[index]);
      if (index != children.length - 1) {
        result.add(spacer);
      }
    }
    return result;
  }
}
