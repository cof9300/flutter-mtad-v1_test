import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/config/service_locator.dart';

class ContentUpdateService {
  static const String _keyLastCheckTime = 'content_update_last_check_time';
  static const Duration _checkThrottle = Duration(minutes: 5);
  static const Duration _flagCheckTimeout = Duration(seconds: 5);

  final _serviceLocator = ServiceLocator();

  Future<bool> checkAndUpdateIfNeeded(
    String token, {
    bool force = false,
    Function(double, String)? onProgress,
  }) async {
    // Force content update for testing to pull newly registered videos
    try {
      await performUpdate(token, onProgress: onProgress);
      return true;
    } on TimeoutException {
      print('[ContentUpdate] Flag check timed out after ${_flagCheckTimeout.inSeconds}s - skipping');
      return false;
    } catch (e) {
      print('[ContentUpdate] Flag check failed: $e - skipping');
      return false;
    }
  }

  Future<bool> _isWithinThrottle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_keyLastCheckTime);
      if (lastCheck == null) return false;
      final elapsed =
          DateTime.now().millisecondsSinceEpoch - lastCheck;
      return elapsed < _checkThrottle.inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _keyLastCheckTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> resetThrottle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastCheckTime);
    } catch (_) {}
  }

  Future<void> performUpdate(
    String token, {
    Function(double, String)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '기존 콘텐츠 삭제 중...');
      await _serviceLocator.contentStorageService.clearAllStoredContent();

      onProgress?.call(0.1, '콘텐츠 정보 조회 중...');
      final waitFuture = _serviceLocator.authRepository.getWaitPageOption(token);
      final resultFuture = _serviceLocator.authRepository.getResultPageOption(token);
      final agreementFuture = _serviceLocator.authRepository.getAgreementOption(token);
      final deviceFuture = _serviceLocator.authRepository.getDevice(token);

      final waitPageOption = await waitFuture;
      final resultPageOption = await resultFuture;
      final agreementOption = await agreementFuture;
      final deviceListResponse = await deviceFuture;

      onProgress?.call(0.2, '디바이스 옵션 조회 중...');
      final devicePageOptionFutures = deviceListResponse.devices
          .map((device) => _serviceLocator.authRepository.getDevicePageOption(
                token: token,
                device: device.type,
              ))
          .toList();
      final devicePageOptions = await Future.wait(devicePageOptionFutures);

      onProgress?.call(0.4, '콘텐츠 다운로드 중...');
      final saveFutures = <Future>[
        _serviceLocator.contentStorageService.saveWaitPageOption(waitPageOption),
        _serviceLocator.contentStorageService.saveResultPageOption(resultPageOption),
        _serviceLocator.contentStorageService.saveAgreementOption(agreementOption),
        ...deviceListResponse.devices.asMap().entries.map(
              (e) => _serviceLocator.contentStorageService.saveDevicePageOption(
                e.value.type,
                devicePageOptions[e.key],
              ),
            ),
      ];
      await Future.wait(saveFutures);

      onProgress?.call(0.9, '업데이트 완료 처리 중...');
      try {
        await _serviceLocator.authRepository.setKioskOptionUseFlag(
          token: token,
          type: 'ALL',
        );
      } catch (e) {
        print('[ContentUpdate] setKioskOptionUseFlag failed (non-fatal): $e');
      }

      await _saveLastCheckTime();
      onProgress?.call(1.0, '업데이트 완료');
    } catch (e) {
      rethrow;
    }
  }
}
