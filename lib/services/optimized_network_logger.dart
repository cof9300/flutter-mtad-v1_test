import 'dart:async';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_template/config/app_version.dart';

class OptimizedNetworkLogger {
  static final OptimizedNetworkLogger _instance = OptimizedNetworkLogger._internal();
  factory OptimizedNetworkLogger() => _instance;
  OptimizedNetworkLogger._internal() {
    _initDeviceId();
    _startBatchTimer();
  }

  final Queue<Map<String, dynamic>> _logQueue = Queue();
  Timer? _batchTimer;
  String _deviceId = 'device_ID_unknown';
  String? _kioskId;
  String? _hardwareSuffix;

  static const int batchSize = 50;
  static const Duration batchInterval = Duration(seconds: 5);
  static const int maxQueueSize = 1000;

  bool _isSending = false;
  bool _isHardwareIdInitialized = false;

  String get _serverUrl {
    final url = dotenv.env['LOG_SERVER_URL'] ?? '';
    if (url.isEmpty) {
      return 'http://43.203.201.107:8000/api/logs/batch';
    }
    return url;
  }

  void _rebuildDeviceId() {
    if (_kioskId != null && _kioskId!.isNotEmpty) {
      if (_hardwareSuffix != null && _hardwareSuffix!.isNotEmpty) {
        _deviceId = 'device_ID_${_kioskId}_$_hardwareSuffix';
      } else {
        _deviceId = 'device_ID_$_kioskId';
      }
    } else if (_hardwareSuffix != null && _hardwareSuffix!.isNotEmpty) {
      _deviceId = 'device_ID_$_hardwareSuffix';
    }
  }

  Future<void> _initDeviceId() async {
    if (_isHardwareIdInitialized) return;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _hardwareSuffix =
            '${androidInfo.model}_${androidInfo.id}'.replaceAll(' ', '_');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _hardwareSuffix =
            '${iosInfo.name}_${iosInfo.identifierForVendor ?? iosInfo.model}'
                .replaceAll(' ', '_');
      } else {
        _hardwareSuffix = 'unknown';
      }
      _isHardwareIdInitialized = true;
      _rebuildDeviceId();
    } catch (e) {
      _isHardwareIdInitialized = true;
    }
  }

  void setKioskId(String kioskId) {
    _kioskId = kioskId;
    _rebuildDeviceId();
  }

  void log(
    String message, {
    String level = 'INFO',
    String? errorCode,
    String? severity,
    String? deviceType,
    Map<String, dynamic>? extraContext,
  }) {
    if (_logQueue.length >= maxQueueSize) {
      // 큐가 가득 차면 가장 오래된 INFO 로그를 우선 제거하여 ERROR/WARN을 보존한다.
      _evictOldestInfoOrFront();
    }

    final entry = <String, dynamic>{
      'timestamp': _localIso8601(DateTime.now()),
      'level': level,
      'message': message,
    };

    if (_kioskId != null && _kioskId!.isNotEmpty) {
      entry['kioskId'] = _kioskId;
    }
    entry['appVersion'] = AppVersion.displayVersion;

    if (errorCode != null) entry['errorCode'] = errorCode;
    if (severity != null) entry['severity'] = severity;
    if (deviceType != null) entry['deviceType'] = deviceType;
    if (extraContext != null) entry['extraContext'] = extraContext;

    _logQueue.add(entry);
  }

  void _evictOldestInfoOrFront() {
    // Queue를 한 번 순회해 첫 번째 INFO 항목을 제거. 없으면 맨 앞 제거.
    final iter = _logQueue.iterator;
    final tmp = <Map<String, dynamic>>[];
    bool evicted = false;
    while (iter.moveNext()) {
      final e = iter.current;
      if (!evicted && (e['level'] == 'INFO')) {
        evicted = true;
        continue;
      }
      tmp.add(e);
    }
    if (!evicted && tmp.isNotEmpty) {
      // INFO가 없으면 맨 앞 1개를 그냥 제거
      tmp.removeAt(0);
    }
    _logQueue
      ..clear()
      ..addAll(tmp);
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(batchInterval, (_) {
      _sendBatch();
    });
  }

  Future<void> _sendBatch() async {
    if (_isSending || _logQueue.isEmpty) return;

    _isSending = true;

    try {
      final batch = <Map<String, dynamic>>[];

      while (batch.length < batchSize && _logQueue.isNotEmpty) {
        batch.add(_logQueue.removeFirst());
      }

      if (batch.isEmpty) return;

      await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
        body: json.encode({
          'device_id': _deviceId,
          'logs': batch,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      // 로그 전송 실패는 무시 (무한 재시도 방지)
    } finally {
      _isSending = false;
    }
  }

  Future<void> flush() async {
    while (_logQueue.isNotEmpty) {
      await _sendBatch();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
    flush();
  }

  /// 기기 로컬 시각을 ISO 8601 형식(+09:00 등 오프셋 포함)으로 반환한다.
  /// 예: 2026-05-14T12:49:03.357+09:00
  static String _localIso8601(DateTime dt) {
    final t = dt.isUtc ? dt.toLocal() : dt;
    final offset = t.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${t.year}-'
        '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}T'
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}'
        '$sign$hh:$mm';
  }
}
