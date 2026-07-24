import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/bluetooth_service.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';
import 'package:flutter_template/providers/notifier/device_bluetooth_mappings_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';

class BluetoothScanScreen extends ConsumerStatefulWidget {
  final String deviceType;
  final String deviceName;

  const BluetoothScanScreen({
    super.key,
    required this.deviceType,
    required this.deviceName,
  });

  @override
  ConsumerState<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends ConsumerState<BluetoothScanScreen> {
  final BleService _bluetoothService = ServiceLocator().bleService;
  List<BluetoothDevice> _foundDevices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  Timer? _progressTimer;
  double _progress = 0.0;
  StreamSubscription<BleConnectionStatus>? _statusSub;

  Duration get _totalDuration {
    return const Duration(seconds: 15);
  }

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
    _bluetoothService.stopScan();
    _progressTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    final hasPermission = await _bluetoothService.requestPermissions();
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
    });

    int elapsedMs = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      elapsedMs += 200;
      final ratio = elapsedMs / _totalDuration.inMilliseconds;
      if (mounted) {
        setState(() {
          _progress = ratio.clamp(0.0, 1.0);
        });
      }
      if (elapsedMs >= _totalDuration.inMilliseconds) {
        t.cancel();
      }
    });

    try {
      final devices = await _bluetoothService.scanForOmronDevices();
      if (mounted) {
        setState(() {
          _foundDevices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
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
    setState(() {
      _isConnecting = true;
    });

    _statusSub?.cancel();

    StreamSubscription<BluetoothBondState>? bondStateSub;
    bool pairingCompleted = false;

    // 페어링 상태 리스너
    bondStateSub = device.bondState.listen((bondState) async {
      if (!mounted || pairingCompleted) return;
      
      debugPrint('[BluetoothScanScreen] Bond state changed: $bondState');
      
      if (bondState == BluetoothBondState.bonded) {
        pairingCompleted = true;
        await bondStateSub!.cancel();
        
        // 페어링 완료 후 매핑 추가 및 화면 닫기
        await _completePairing(device);
      } else if (bondState == BluetoothBondState.none && _isConnecting) {
        // 페어링이 취소된 경우 (연결 후 페어링 시작 전에 취소된 경우는 제외)
        // 연결이 완료된 후에만 취소로 처리
        if (device.isConnected) {
          setState(() {
            _isConnecting = false;
          });
          await bondStateSub!.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '페어링이 취소되었습니다.',
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: _getResponsiveSize(context, 28),
                ),
              ),
            ),
          );
        }
      }
    });

    _statusSub = _bluetoothService.connectionStatusStream.listen((status) async {
      if (!mounted) return;

      switch (status) {
        case BleConnectionStatus.connected:
          // 연결 완료 후 페어링 시작
          // 페어링 상태는 bondState 리스너에서 처리됨
          // 여기서는 페어링만 시작하고, 완료는 bondState 리스너에서 처리
          try {
            debugPrint('[BluetoothScanScreen] Connected. Starting bond process...');
            
            // 페어링이 필요하면 시작 (bondState 리스너가 완료를 감지함)
            // 이미 페어링된 경우 bondState 리스너에서 bonded 상태를 받아서 처리됨
            if (device.prevBondState == BluetoothBondState.none) {
              await device.createBond();
              debugPrint('[BluetoothScanScreen] Bond creation requested, waiting for completion...');
            } else {
              // 이미 페어링 중이거나 완료된 경우, bondState 리스너가 처리함
              debugPrint('[BluetoothScanScreen] Bond state: ${device.prevBondState}, waiting for bondState listener...');
            }
          } catch (e) {
            debugPrint('[BluetoothScanScreen] Error in bond process: $e');
            if (mounted) {
              setState(() {
                _isConnecting = false;
              });
              await bondStateSub?.cancel();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '페어링 중 오류가 발생했습니다.',
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

        case BleConnectionStatus.disconnected:
          // 연결 중에 disconnected가 발생한 경우 (페어링 실패)
          if (mounted && _isConnecting) {
            setState(() {
              _isConnecting = false;
            });
            _statusSub?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '페어링을 실패했습니다.\n다시 시도해주세요.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 28),
                  ),
                ),
              ),
            );
          }
          break;

        case BleConnectionStatus.connecting:
        case BleConnectionStatus.disconnecting:
          break;
      }
    });

    try {
      await _bluetoothService.connect(device, autoConnect: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        // 연결 중 오류가 발생해도 모달은 닫지 않음 (사용자가 취소 버튼을 눌러야 닫힘)
        _statusSub?.cancel();
        await bondStateSub.cancel();
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

  Future<void> _completePairing(BluetoothDevice device) async {
    if (!mounted) return;

    try {
      // 혈압계인 경우 혈압 서비스 설정 및 구독
      if (widget.deviceType.toUpperCase() == 'BP') {
        try {
          await Future.delayed(const Duration(milliseconds: 500)); // 연결 안정화 대기
          await _bluetoothService.setupBloodPressureService();
        } catch (e) {
          debugPrint('[BluetoothScanScreen] Failed to setup BP service: $e');
        }
      }

      final mapping = DeviceBluetoothMapping(
        deviceType: widget.deviceType,
        deviceName: device.platformName.isNotEmpty
            ? device.platformName
            : widget.deviceName,
        macAddress: device.remoteId.str,
        deviceId: device.remoteId.str,
      );

      await ref.read(deviceBluetoothMappingsProvider.notifier).addMapping(mapping);

          if (mounted) {
            setState(() {
              _isConnecting = false;
            });
            _statusSub?.cancel();
            Navigator.of(context).pop(true); // 성공적으로 완료됨을 알림
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${device.platformName.isNotEmpty ? device.platformName : widget.deviceName} 연결 완료',
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
      debugPrint('[BluetoothScanScreen] Error completing pairing: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
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

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isConnecting,
      onPopInvoked: (didPop) {
        if (didPop && _isConnecting) {
          // 연결 중에는 뒤로 가기로 닫히지 않도록 함
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '블루투스 기기 검색',
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
                    _bluetoothService.stopScan();
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
                _isScanning ? '기기를 찾고 있습니다' : '기기 검색 완료',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 32),
                  fontVariations: <FontVariation>[FontVariation('wght', 600)],
                  fontFamily: AppTextStyles.bodyFontFamily,
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 12)),
              Text(
                _isScanning
                    ? (widget.deviceType.toUpperCase() == 'BP'
                        ? '오므론 혈압계를 찾고 있습니다.\n최대 15초 정도 소요될 수 있습니다.'
                        : '최대 15초 정도 소요될 수 있습니다.')
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
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ],
              if (!_isScanning && _foundDevices.isNotEmpty) ...[
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
                        margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 16)),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth_connected, color: AppColors.primary),
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
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _isConnecting
                              ? null
                              : () => _connectDevice(device),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!_isScanning && _foundDevices.isEmpty) ...[
                SizedBox(height: _getResponsiveSize(context, 40)),
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _startScan,
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
