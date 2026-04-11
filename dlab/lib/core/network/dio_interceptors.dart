import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<Interceptor> buildInterceptors({
  required Dio dio,
  required Logger logger,
  required bool enableLogs,
}) {
  return [
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired — sign out so AuthStateNotifier picks it up.
          await Supabase.instance.client.auth.signOut();
        }
        handler.next(error);
      },
    ),
    if (enableLogs)
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          final str = obj
              .toString()
              .replaceAll(
                RegExp(r'Authorization: Bearer .*', caseSensitive: false),
                'Authorization: ***',
              );
          logger.d(str);
        },
      ),
  ];
}

