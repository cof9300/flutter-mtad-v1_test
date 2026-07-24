import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/service_locator.dart';

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false);

  static const _channel = MethodChannel('kiosk_lock_channel');

  Future<void> initialize() async {
    final locked = await ServiceLocator().appLockService.isLocked();
    state = locked;
  }

  Future<void> setLocked(bool locked) async {
    await ServiceLocator().appLockService.setLocked(locked);
    state = locked;
    // 잠금 상태에 따라 네이티브 Immersive 모드 갱신
    try {
      await _channel.invokeMethod(locked ? 'startKiosk' : 'stopKiosk');
    } catch (_) {}
  }

  Future<bool> isDeviceOwner() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;
    } catch (_) {
      return false;
    }
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  final notifier = AppLockNotifier();
  notifier.initialize();
  return notifier;
});
