/// Barrel file that re-exports the correct implementation via conditional
/// imports.  On web the `web_http_client.dart` stub is used; on native
/// platforms the real `native_http_client.dart` is loaded.
library;

export 'web_http_client.dart'
    if (dart.library.io) 'native_http_client.dart';
