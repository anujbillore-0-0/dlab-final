import 'package:dio/dio.dart';

import '../error/failure.dart';

class NetworkFailureMapper {
  NetworkFailureMapper._();

  static Failure fromDio(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final message = _messageFrom(error);
      return NetworkFailure(message: message, statusCode: statusCode);
    }

    return UnknownFailure(message: 'Unexpected error');
  }

  static String _messageFrom(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection';
    }

    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Something went wrong';
  }
}
