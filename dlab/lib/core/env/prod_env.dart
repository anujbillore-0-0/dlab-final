import 'env.dart';

class ProdEnv extends Env {
  const ProdEnv();

  @override
  String get name => 'prod';

  @override
  String get baseUrl => 'http://app.dezign-lab.com:3000/api'; // TODO: switch to https:// after SSL + Nginx are configured

  @override
  bool get enableNetworkLogs => false;
}
