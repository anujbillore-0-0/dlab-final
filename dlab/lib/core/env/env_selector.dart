import 'dev_env.dart';
import 'env.dart';
import 'prod_env.dart';
import 'staging_env.dart';

/// Compile-time environment selection.
///
/// Build examples:
/// flutter run --flavor dev --dart-define=APP_ENV=dev
/// flutter run --flavor staging --dart-define=APP_ENV=staging
/// flutter run --flavor prod --dart-define=APP_ENV=prod
class EnvSelector {
  static const String _envKey = 'APP_ENV';

  static Env current() {
    const value = String.fromEnvironment(_envKey, defaultValue: 'prod');

    switch (value) {
      case 'dev':
        return const DevEnv();
      case 'staging':
        return const StagingEnv();
      case 'prod':
      default:
        return const ProdEnv();
    }
  }
}
