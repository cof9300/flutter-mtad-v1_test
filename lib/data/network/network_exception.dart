import 'dart:io';
import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final NetworkExceptionType type;

  const NetworkException({
    required this.message,
    this.statusCode,
    required this.type,
  });

  factory NetworkException.unauthorizedException() {
    return const NetworkException(
      message: '인증이 필요합니다.',
      type: NetworkExceptionType.unauthorized,
    );
  }

  factory NetworkException.otherException(Type errorType) {
    return NetworkException(
      message: '알 수 없는 오류가 발생했습니다: $errorType',
      type: NetworkExceptionType.other,
    );
  }

  factory NetworkException.formatException() {
    return const NetworkException(
      message: '데이터 형식 오류가 발생했습니다.',
      type: NetworkExceptionType.format,
    );
  }

  factory NetworkException.connectionException() {
    return const NetworkException(
      message: '네트워크 연결이 불안정합니다.',
      type: NetworkExceptionType.connection,
    );
  }

  factory NetworkException.apiException({
    int? statusCode,
    String? message,
  }) {
    return NetworkException(
      message: message ?? '서버 오류가 발생했습니다.',
      statusCode: statusCode,
      type: NetworkExceptionType.api,
    );
  }

  static NetworkException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.connectionException();

      case DioExceptionType.badResponse:
        String? message;
        try {
          final json = error.response?.data as Map;
          message ??= json['Message'] as String?;
          message ??= json['message'] as String?;
        } catch (_) {}
        message ??= error.message;

        return NetworkException.apiException(
          statusCode: error.response?.statusCode,
          message: message,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException.connectionException();
        } else if (error.error is FormatException || error.error is TypeError) {
          return NetworkException.formatException();
        }
    }
    return NetworkException.otherException(error.runtimeType);
  }

  static NetworkException getException(Object error) {
    if (error is NetworkException) {
      return error;
    } else if (error is SocketException) {
      return NetworkException.connectionException();
    } else if (error is FormatException || error is TypeError) {
      return NetworkException.formatException();
    } else if (error is DioException) {
      return fromDioException(error);
    }
    return NetworkException.otherException(error.runtimeType);
  }

  @override
  String toString() => message;
}

enum NetworkExceptionType {
  unauthorized,
  other,
  format,
  connection,
  api,
}
