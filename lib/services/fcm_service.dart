import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// FCM 에러 코드 정의
// FCM-001 : 알림 권한 승인
// FCM-002 : 알림 권한 거부
// FCM-003 : 디바이스 토큰 발급
// FCM-004 : 디바이스 토큰 등록 성공 (서버)
// FCM-005 : 디바이스 토큰 등록 실패 (서버)
// FCM-006 : 디바이스 토큰 갱신
// FCM-007 : 포어그라운드 메시지 수신
// FCM-008 : 백그라운드 메시지 수신
// FCM-009 : 알림 탭으로 앱 열림
// FCM-010 : 토큰 조회/초기화 오류
// FCM-011 : 앱 잠금 명령 수신 (ON)
// FCM-012 : 앱 잠금 명령 수신 (OFF)
// ─────────────────────────────────────────────

/// 백그라운드 핸들러에서 pending 잠금 명령을 저장하는 SharedPreferences 키
const _kPendingLockKey = 'pending_fcm_lock';

/// FCM 백그라운드 핸들러 (별도 isolate → 메인 Logger 미사용)
/// app_lock 명령이면 SharedPreferences에 저장 후, 로그 서버에 직접 전송한다.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // app_lock 명령 처리 — SharedPreferences에 저장해두면 앱 복귀 시 적용된다.
  final action = message.data['action'];
  final value = message.data['value'];
  if (action == 'app_lock' && (value == 'on' || value == 'off')) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingLockKey, value);
  }

  // 로그 서버에 직접 전송
  try {
    final url = dotenv.env['LOG_SERVER_URL'] ?? 'http://43.203.201.107:8000/api/logs/batch';
    final baseUrl = _extractBaseUrl(url);
    final isLockCommand = action == 'app_lock';
    final errorCode = isLockCommand
        ? (value == 'on' ? 'FCM-011' : 'FCM-012')
        : 'FCM-008';

    await http.post(
      Uri.parse('$baseUrl/api/logs/batch'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'device_id': 'device_ID_unknown_background',
        'logs': [
          {
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'level': 'INFO',
            'message': isLockCommand
                ? '[FCM] 백그라운드 앱 잠금 명령 수신 - value: $value'
                : '[FCM] 백그라운드 메시지 수신 - title: ${message.notification?.title}, body: ${message.notification?.body}',
            'errorCode': errorCode,
            'severity': 'INFO',
          }
        ],
      }),
    ).timeout(const Duration(seconds: 5));
  } catch (_) {}
}

String _extractBaseUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null) return '${uri.scheme}://${uri.host}:${uri.port}';
  return url;
}

class FcmService {
  static final FcmService _instance = FcmService._();
  FcmService._();
  factory FcmService() => _instance;

  final _messaging = FirebaseMessaging.instance;
  String? _kioskId;

  // 포어그라운드 잠금 명령 스트림 (main.dart에서 구독)
  final _lockCommandController = StreamController<bool>.broadcast();
  Stream<bool> get lockCommandStream => _lockCommandController.stream;

  String get _logServerBaseUrl {
    final url = dotenv.env['LOG_SERVER_URL'] ?? '';
    if (url.isEmpty) return 'http://43.203.201.107:8000';
    return _extractBaseUrl(url);
  }

  Future<void> initialize({String? kioskId}) async {
    _kioskId = kioskId;

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 알림 권한 요청
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: false,
      sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    FlutterErrorLogger.system(
      '[FCM] 알림 권한: ${settings.authorizationStatus.name}',
      errorCode: granted ? 'FCM-001' : 'FCM-002',
      severity: granted ? 'INFO' : 'WARN',
    );

    // 토큰 발급 및 서버 등록
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        FlutterErrorLogger.system(
          '[FCM] 디바이스 토큰 발급',
          errorCode: 'FCM-003',
          severity: 'INFO',
          extraContext: {'token': token},
        );
        await _registerToken(token);
      }
    } catch (e) {
      FlutterErrorLogger.system(
        '[FCM] 토큰 조회/초기화 오류: $e',
        errorCode: 'FCM-010',
        severity: 'ERROR',
      );
    }

    // 토큰 갱신 시 자동 재등록
    _messaging.onTokenRefresh.listen((newToken) async {
      FlutterErrorLogger.system(
        '[FCM] 토큰 갱신',
        errorCode: 'FCM-006',
        severity: 'INFO',
        extraContext: {'token': newToken},
      );
      await _registerToken(newToken);
    });

    // 포어그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((message) {
      final action = message.data['action'];
      final value = message.data['value'];

      if (action == 'app_lock') {
        final shouldLock = value == 'on';
        FlutterErrorLogger.system(
          '[FCM] 앱 잠금 명령 수신 - value: $value',
          errorCode: shouldLock ? 'FCM-011' : 'FCM-012',
          severity: 'INFO',
          extraContext: {'action': action, 'value': value},
        );
        _lockCommandController.add(shouldLock);
        return;
      }

      FlutterErrorLogger.system(
        '[FCM] 포어그라운드 메시지 수신 - title: ${message.notification?.title}, body: ${message.notification?.body}',
        errorCode: 'FCM-007',
        severity: 'INFO',
        extraContext: {
          if (message.data.isNotEmpty) 'data': message.data,
        },
      );
    });

    // 알림 탭으로 앱 열림
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      FlutterErrorLogger.system(
        '[FCM] 알림 탭으로 앱 열림 - title: ${message.notification?.title}',
        errorCode: 'FCM-009',
        severity: 'INFO',
        extraContext: {
          if (message.data.isNotEmpty) 'data': message.data,
        },
      );
    });
  }

  /// 백그라운드에서 저장된 pending 잠금 명령을 읽어 스트림으로 방출한 뒤 삭제한다.
  /// 앱이 포어그라운드로 복귀할 때 (didChangeAppLifecycleState: resumed) 호출한다.
  Future<void> applyPendingLockCommand() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString(_kPendingLockKey);
      if (pending != null) {
        await prefs.remove(_kPendingLockKey);
        final shouldLock = pending == 'on';
        FlutterErrorLogger.system(
          '[FCM] 백그라운드 앱 잠금 명령 적용 - value: $pending',
          errorCode: shouldLock ? 'FCM-011' : 'FCM-012',
          severity: 'INFO',
        );
        _lockCommandController.add(shouldLock);
      }
    } catch (_) {}
  }

  void dispose() {
    _lockCommandController.close();
  }

  /// PUT /api/fcm/tokens { deviceId, fcmToken }
  Future<void> _registerToken(String fcmToken) async {
    final deviceId = _kioskId;
    if (deviceId == null || deviceId.isEmpty) {
      FlutterErrorLogger.system(
        '[FCM] 키오스크 ID 없음 — 토큰 등록 스킵',
        errorCode: 'FCM-005',
        severity: 'WARN',
      );
      return;
    }

    try {
      final url = Uri.parse('$_logServerBaseUrl/api/fcm/tokens');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        FlutterErrorLogger.system(
          '[FCM] 토큰 등록 성공 - deviceId: $deviceId',
          errorCode: 'FCM-004',
          severity: 'INFO',
        );
      } else {
        FlutterErrorLogger.system(
          '[FCM] 토큰 등록 실패 - status: ${response.statusCode}, body: ${response.body}',
          errorCode: 'FCM-005',
          severity: 'WARN',
        );
      }
    } catch (e) {
      FlutterErrorLogger.system(
        '[FCM] 토큰 등록 요청 실패: $e',
        errorCode: 'FCM-005',
        severity: 'ERROR',
      );
    }
  }
}
