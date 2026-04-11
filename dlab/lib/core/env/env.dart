abstract class Env {
  const Env();

  String get name;
  String get baseUrl;

  /// When true, extra logs may be enabled. Never log auth tokens.
  bool get enableNetworkLogs;
}
