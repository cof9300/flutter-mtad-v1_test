import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/core/utils/alco_ble_service.dart';

class AlcoConnectionStatusNotifier extends StateNotifier<bool> {
  AlcoConnectionStatusNotifier() : super(false) {
    _init();
  }

  StreamSubscription<AlcoBleConnectionStatus>? _subscription;

  void _init() {
    final alcoBleService = ServiceLocator().alcoBleService;
    state = alcoBleService.isConnected;

    _subscription = alcoBleService.connectionStatusStream.listen((status) {
      if (mounted) {
        state = status == AlcoBleConnectionStatus.connected;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final alcoConnectionStatusProvider =
    StateNotifierProvider<AlcoConnectionStatusNotifier, bool>((ref) {
  return AlcoConnectionStatusNotifier();
});
