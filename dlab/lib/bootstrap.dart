import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/platform_http_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/wishlist_service.dart';

Future<void> bootstrap(ProviderContainer container) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Install native HttpOverrides (no-op on web).
  installNativeHttpOverrides();

  await Supabase.initialize(
    url: 'https://zzqeibxwasikdmdoijfb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6cWVpYnh3YXNpa2RtZG9pamZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5OTQwMTAsImV4cCI6MjA4NzU3MDAxMH0.guvKAPuNIw8Ln5m-r6i99eGu2tOjuHvNArYfh9Q2Prk',
  );

  await WishlistService.instance.initialize();
  await PushNotificationService.instance.initialize();
}

