import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/alco_bluetooth_constants.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/alco_ble_service.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';
import 'package:flutter_template/providers/notifier/device_bluetooth_mappings_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';

class AlcoBluetoothScanScreen extends ConsumerStatefulWidget {
  const AlcoBluetoothScanScreen({super.key});

  @override
  ConsumerState<AlcoBluetoothScanScreen> createState() =>
      _AlcoBluetoothScanScreenState();
}

class _AlcoBluetoothScanScreenState
    extends ConsumerState<AlcoBluetoothScanScreen> {
  final AlcoBleService _alcoBleService = ServiceLocator().alcoBleService;

  List<BluetoothDevice> _foundDevices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  double _progress = 0.0;
  Timer? _progressTimer;
  StreamSubscription<AlcoBleConnectionStatus>? _statusSub;

  static const Duration _scanDuration =
      Duration(seconds: AlcoBluetoothConstants.scanTimeoutSeconds);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _startScan();
  }

  @override
  void dispose() {
    _alcoBleService.stopScan();
    _progressTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  Future<void> _startScan() async {
    final hasPermission = await _alcoBleService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '블루투스 권한이 필요합니다.',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 28),
              ),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _foundDevices = [];
    });

    int elapsedMs = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      elapsedMs += 200;
      final ratio = elapsedMs / _scanDuration.inMilliseconds;
      if (mounted) {
        setState(() {
          _progress = ratio.clamp(0.0, 1.0);
        });
      }
      if (elapsedMs >= _scanDuration.inMilliseconds) t.cancel();
    });

    try {
      final devices = await _alcoBleService.scanForAlcoDevices();
      if (mounted) {
        setState(() {
          _foundDevices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '스캔 중 오류가 발생했습니다: $e',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 28),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    _statusSub?.cancel();

    _statusSub = _alcoBleService.connectionStatusStream.listen((status) async {
      if (!mounted) return;

      switch (status) {
        case AlcoBleConnectionStatus.connected:
          _statusSub?.cancel();
          await _completeRegistration(device);
          break;

        case AlcoBleConnectionStatus.disconnected:
          if (_isConnecting) {
            setState(() => _isConnecting = false);
            _statusSub?.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '연결에 실패했습니다. 다시 시도해주세요.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: _getResponsiveSize(context, 28),
                    ),
                  ),
                ),
              );
            }
          }
          break;

        case AlcoBleConnectionStatus.connecting:
        case AlcoBleConnectionStatus.disconnecting:
          break;
      }
    });

    try {
      await _alcoBleService.connect(device, autoConnect: false);
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        _statusSub?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '연결 중 오류가 발생했습니다: $e',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 28),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeRegistration(BluetoothDevice device) async {
    if (!mounted) return;

    try {
      final deviceName =
          device.platformName.isNotEmpty ? device.platformName : 'ALCOFIND';

      final mapping = DeviceBluetoothMapping(
        deviceType: 'AL',
        deviceName: deviceName,
        macAddress: device.remoteId.str,
        deviceId: device.remoteId.str,
      );

      await ref
          .read(deviceBluetoothMappingsProvider.notifier)
          .addMapping(mapping);

      if (mounted) {
        setState(() => _isConnecting = false);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$deviceName 연결 완료',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 28),
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '등록 중 오류가 발생했습니다: $e',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 28),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isConnecting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '음주측정기 검색',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 36),
            ),
          ),
          leading: _isConnecting
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _alcoBleService.stopScan();
                    _statusSub?.cancel();
                    Navigator.of(context).pop();
                  },
                ),
        ),
        body: Padding(
          padding: EdgeInsets.all(_getResponsiveSize(context, 40)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth,
                size: _getResponsiveSize(context, 80),
                color: AppColors.primary,
              ),
              SizedBox(height: _getResponsiveSize(context, 24)),
              Text(
                _isScanning
                    ? '기기를 찾고 있습니다'
                    : _isConnecting
                        ? '기기에 연결 중입니다'
                        : '기기 검색 완료',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 32),
                  fontVariations: <FontVariation>[FontVariation('wght', 600)],
                  fontFamily: AppTextStyles.bodyFontFamily,
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 12)),
              Text(
                _isScanning
                    ? 'AF-50AD 음주측정기를 찾고 있습니다.\n최대 15초 정도 소요될 수 있습니다.'
                    : _isConnecting
                        ? '잠시만 기다려주세요.'
                        : '${_foundDevices.length}개의 기기가 발견되었습니다.',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 26),
                  color: const Color(0xFF757575),
                  fontFamily: AppTextStyles.bodyFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isScanning) ...[
                SizedBox(height: _getResponsiveSize(context, 32)),
                SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ],
              if (_isConnecting) ...[
                SizedBox(height: _getResponsiveSize(context, 32)),
                const CircularProgressIndicator(),
              ],
              if (!_isScanning && !_isConnecting && _foundDevices.isNotEmpty) ...[
                SizedBox(height: _getResponsiveSize(context, 40)),
                Expanded(
                  child: ListView.builder(
                    itemCount: _foundDevices.length,
                    itemBuilder: (context, index) {
                      final device = _foundDevices[index];
                      final deviceName = device.platformName.isNotEmpty
                          ? device.platformName
                          : '알 수 없는 기기';
                      return Card(
                        margin: EdgeInsets.only(
                            bottom: _getResponsiveSize(context, 16)),
                        child: ListTile(
                          leading: const Icon(
                            Icons.bluetooth_connected,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            deviceName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: _getResponsiveSize(context, 30),
                              fontVariations: <FontVariation>[FontVariation('wght', 600)],
                            ),
                          ),
                          subtitle: Text(
                            device.remoteId.str,
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: _getResponsiveSize(context, 24),
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _connectDevice(device),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!_isScanning && !_isConnecting && _foundDevices.isEmpty) ...[
                SizedBox(height: _getResponsiveSize(context, 40)),
                ElevatedButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    '다시 검색',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: _getResponsiveSize(context, 30),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSize(context, 32),
                      vertical: _getResponsiveSize(context, 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
