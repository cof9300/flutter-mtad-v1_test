import 'dart:async';
import 'package:flutter/material.dart';

mixin AutoReturnMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoReturnTimer;
  int _currentTimerSeconds = 0;

  void startAutoReturnTimer(int seconds) {
    cancelAutoReturnTimer();
    _currentTimerSeconds = seconds;
    
    if (seconds > 0) {
      _autoReturnTimer = Timer(Duration(seconds: seconds), () {
        if (mounted) {
          _onAutoReturn();
        }
      });
    }
  }

  void resetAutoReturnTimer(int seconds) {
    startAutoReturnTimer(seconds);
  }

  void resetCurrentTimer() {
    if (_currentTimerSeconds > 0) {
      resetAutoReturnTimer(_currentTimerSeconds);
    }
  }

  void cancelAutoReturnTimer() {
    _autoReturnTimer?.cancel();
    _autoReturnTimer = null;
    _currentTimerSeconds = 0;
  }

  void _onAutoReturn() {
    if (!mounted) return;
    closeModalsBeforeReturn();
    if (!mounted) return;
    onBeforeAutoReturn().then((_) {
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: false)
            .popUntil((route) => route.isFirst);
      } catch (e) {
        debugPrint('[AutoReturnMixin] 네비게이션 오류: $e');
      }
    });
  }

  Future<void> onBeforeAutoReturn() async {}

  void closeModalsBeforeReturn() {
    // 기본 구현은 비어있음
    // 하위 클래스에서 오버라이드하여 모달을 닫을 수 있음
  }

  @override
  void dispose() {
    cancelAutoReturnTimer();
    super.dispose();
  }
}















