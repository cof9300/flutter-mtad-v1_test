import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/service_locator.dart';

class AlcoUsbConnectionStatusNotifier extends StateNotifier<bool> {
  AlcoUsbConnectionStatusNotifier() : super(false) {
    _init();
  }

  StreamSubscription<bool>? _subscription;

  void _init() {
    final alcoUsbService = ServiceLocator().alcoUsbService;
    state = alcoUsbService.isConnected;

    _subscription = alcoUsbService.connectionStatusStream.listen((connected) {
      if (mounted) {
        state = connected;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final alcoUsbConnectionStatusProvider =
    StateNotifierProvider<AlcoUsbConnectionStatusNotifier, bool>((ref) {
  return AlcoUsbConnectionStatusNotifier();
});
