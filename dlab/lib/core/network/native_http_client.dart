/// Native (Android/iOS/desktop) implementation.
///
/// Installs [HttpOverrides] with a reasonable connection timeout and DIRECT
/// proxy so Dart doesn't attempt to read desktop-style proxy env vars on
/// mobile.
library;

import 'dart:io';

/// Installs global [HttpOverrides] for native platforms.
void installNativeHttpOverrides() {
  HttpOverrides.global = _AppHttpOverrides();
}

class _AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 15);
    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return 'DIRECT';
  }
}
