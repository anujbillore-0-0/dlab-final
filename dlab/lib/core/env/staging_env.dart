import 'env.dart';

class StagingEnv extends Env {
  const StagingEnv();

  @override
  String get name => 'staging';

  @override
  String get baseUrl => 'https://staging.app.dezign-lab.com/api';

  @override
  bool get enableNetworkLogs => true;
}
