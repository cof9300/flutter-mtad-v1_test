import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_template/services/optimized_network_logger.dart';

class LoggingInterceptor extends Interceptor {
  final OptimizedNetworkLogger _logger = OptimizedNetworkLogger();

  static const int _maxBodyLength = 500;
  static const Set<String> _sensitiveKeys = {'token', 'password', 'certnumber'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method;
    final path = options.path;

    final parts = <String>['[API요청] $method $path'];

    if (options.queryParameters.isNotEmpty) {
      final q = options.queryParameters.entries
          .map((e) => '${e.key}=${_mask(e.key, e.value?.toString() ?? '')}')
          .join(', ');
      parts.add('query: $q');
    }

    if (options.data is Map || options.data is List) {
      final body = _sanitize(options.data);
      final encoded = _compact(body);
      parts.add('body: $encoded');
    }

    final message = parts.join(' | ');
    _devLog(message, type: 0);
    _logger.log(message, level: 'INFO');

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method;
    final path = response.requestOptions.path;
    final status = response.statusCode;

    final parts = <String>['[API응답] $method $path | $status'];

    if (response.data != null) {
      final encoded = _compact(_sanitize(response.data));
      parts.add(encoded);
    }

    final message = parts.join(' | ');
    _devLog(message, type: 1);
    _logger.log(message, level: 'INFO');

    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final method = err.requestOptions.method;
    final path = err.requestOptions.path;
    final status = err.response?.statusCode;
    final errMsg = err.message ?? 'Unknown error';

    final parts = <String>['[API오류] $method $path | ${status ?? 'N/A'} | $errMsg'];

    if (err.response?.data != null) {
      final encoded = _compact(err.response!.data);
      parts.add(encoded);
    }

    final message = parts.join(' | ');
    _devLog(message, type: 2);

    final errorCode = _resolveNetErrorCode(err, status);
    _logger.log(
      message,
      level: 'ERROR',
      errorCode: errorCode,
      severity: 'ERROR',
      extraContext: {
        'endpoint': path,
        'method': method,
        if (status != null) 'statusCode': status,
        'errorType': err.type.name,
      },
    );

    return super.onError(err, handler);
  }

  String _resolveNetErrorCode(DioException err, int? status) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'NET-003';
    }
    if (err.type == DioExceptionType.connectionError) {
      return 'NET-004';
    }
    if (status != null) {
      if (status >= 500) return 'NET-002';
      if (status >= 400) return 'NET-001';
    }
    return 'NET-001';
  }

  String _compact(dynamic data) {
    try {
      final str = const JsonEncoder().convert(data);
      return str.length > _maxBodyLength
          ? '${str.substring(0, _maxBodyLength)}…'
          : str;
    } catch (_) {
      final str = data.toString();
      return str.length > _maxBodyLength
          ? '${str.substring(0, _maxBodyLength)}…'
          : str;
    }
  }

  dynamic _sanitize(dynamic data) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          entry.key: _sensitiveKeys.contains(entry.key.toString().toLowerCase())
              ? '***'
              : entry.value,
      };
    }
    return data;
  }

  String _mask(String key, String value) {
    if (_sensitiveKeys.contains(key.toLowerCase())) return '***';
    return value;
  }
}

void _devLog(String message, {int type = 0}) {
  switch (type) {
    case 0:
      developer.log('\x1B[33m$message', name: 'API');
    case 1:
      developer.log('\x1B[32m$message', name: 'API');
    case 2:
      developer.log('\x1B[31m$message', name: 'API');
    default:
      developer.log(message, name: 'API');
  }
}
