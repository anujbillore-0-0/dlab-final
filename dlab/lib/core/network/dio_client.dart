import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../env/env.dart';
import 'dio_interceptors.dart';

class DioClient {
  DioClient({
    required Env env,
    required Logger logger,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: env.baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            sendTimeout: AppConstants.sendTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    dio.interceptors.addAll(
      buildInterceptors(
        dio: dio,
        logger: logger,
        enableLogs: env.enableNetworkLogs,
      ),
    );
  }

  final Dio dio;
}
