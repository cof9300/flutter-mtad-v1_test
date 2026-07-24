import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/services/optimized_network_logger.dart';

class LogCategory {
  static const String measurement = '[혈압측정]';
  static const String result     = '[측정결과]';
  static const String auth       = '[사용자인증]';
  static const String sms        = '[문자전송]';
  static const String navigation = '[화면이동]';
  static const String system     = '[시스템]';
  static const String device     = '[기기연결]';
  static const String admin      = '[관리자]';
  static const String guest      = '[게스트]';
  static const String error      = '[오류]';
  static const String alco       = '[음주측정]';
  static const String alcoUsb    = '[음주USB]';
  static const String alcoBle    = '[음주BLE]';
}

class FlutterErrorLogger {
  static final OptimizedNetworkLogger _logger = OptimizedNetworkLogger();
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _log(
        '${LogCategory.error} Flutter 프레임워크 오류: ${details.exception}'
        '${details.stack != null ? '\nStack: ${details.stack}' : ''}',
        level: 'ERROR',
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _log(
        '${LogCategory.error} 플랫폼 오류: $error\nStack: $stack',
        level: 'ERROR',
      );
      return true;
    };
  }

  static void setKioskId(String kioskId) {
    _logger.setKioskId(kioskId);
  }

  static void _log(
    String message, {
    String level = 'INFO',
    String? errorCode,
    String? severity,
    String? deviceType,
    Map<String, dynamic>? extraContext,
  }) {
    try {
      _logger.log(
        message,
        level: level,
        errorCode: errorCode,
        severity: severity,
        deviceType: deviceType,
        extraContext: extraContext,
      );
    } catch (_) {}
  }

  static void logInfo(String message) => _log(message, level: 'INFO');

  static void logWarning(String message) => _log(message, level: 'WARNING');

  static void logError(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    try {
      final errorMessage = error != null
          ? '$message\nError: $error${stackTrace != null ? '\nStack: $stackTrace' : ''}'
          : message;
      _log(errorMessage, level: 'ERROR');
    } catch (_) {}
  }

  static void measurement(String action) =>
      _log('${LogCategory.measurement} $action', level: 'INFO');

  static void measurementResult(String action) =>
      _log('${LogCategory.result} $action', level: 'INFO');

  static void userAuth(String action) =>
      _log('${LogCategory.auth} $action', level: 'INFO');

  static void sms(String action) =>
      _log('${LogCategory.sms} $action', level: 'INFO');

  static void navigation(String action) =>
      _log('${LogCategory.navigation} $action', level: 'INFO');

  static void system(
    String action, {
    String? errorCode,
    String? severity,
    Map<String, dynamic>? extraContext,
  }) =>
      _log(
        '${LogCategory.system} $action',
        level: severity ?? 'INFO',
        errorCode: errorCode,
        severity: severity,
        extraContext: extraContext,
      );

  static void device(
    String action, {
    String? errorCode,
    String? severity,
    String? deviceType,
    Map<String, dynamic>? extraContext,
  }) =>
      _log(
        '${LogCategory.device} $action',
        level: severity ?? 'INFO',
        errorCode: errorCode,
        severity: severity,
        deviceType: deviceType,
        extraContext: extraContext,
      );

  static void admin(String action) =>
      _log('${LogCategory.admin} $action', level: 'INFO');

  static void guest(String action) =>
      _log('${LogCategory.guest} $action', level: 'INFO');

  static void warn(
    String category,
    String action, {
    String? errorCode,
    String? deviceType,
    Map<String, dynamic>? extraContext,
  }) =>
      _log(
        '$category $action',
        level: 'WARNING',
        errorCode: errorCode,
        severity: 'WARN',
        deviceType: deviceType,
        extraContext: extraContext,
      );

  static void err(
    String category,
    String action, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    try {
      final msg = error != null
          ? '$category $action\nError: $error${stackTrace != null ? '\nStack: $stackTrace' : ''}'
          : '$category $action';
      _log(msg, level: 'ERROR');
    } catch (_) {}
  }
}
