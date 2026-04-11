import 'env.dart';

class DevEnv extends Env {
  const DevEnv();

  @override
  String get name => 'dev';

  @override
  String get baseUrl => 'http://app.dezign-lab.com:3000/api'; // HTTP until SSL is set up

  @override
  bool get enableNetworkLogs => true;
}
