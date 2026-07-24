import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_template/config/alco_usb_constants.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';
import 'package:flutter_template/config/service_locator.dart';

class AlcoUsbSetupScreen extends StatefulWidget {
  const AlcoUsbSetupScreen({super.key});

  @override
  State<AlcoUsbSetupScreen> createState() => _AlcoUsbSetupScreenState();
}

class _AlcoUsbSetupScreenState extends State<AlcoUsbSetupScreen> {
  List<UsbDevice> _devices = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _refreshDevices();
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  Future<void> _refreshDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await UsbSerial.listDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'USB 기기 검색 중 오류가 발생했습니다: $e',
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

  Future<void> _selectDevice(UsbDevice device) async {
    setState(() => _isSaving = true);
    try {
      final mapping = DeviceUsbMapping(
        deviceType: 'AL',
        portName: device.deviceName,
        vid: device.vid ?? 0,
        pid: device.pid ?? 0,
        baudRate: AlcoUsbConstants.baudRate,
      );

      await ServiceLocator().deviceUsbMappingStorage.saveMapping(mapping);
      await ServiceLocator().alcoUsbService.tryConnectSavedDevice();

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AF-50U USB 음주측정기 등록 완료',
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
        setState(() => _isSaving = false);
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
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'USB 음주측정기 등록',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 36),
            ),
          ),
          leading: _isSaving
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
        ),
        body: Padding(
          padding: EdgeInsets.all(_getResponsiveSize(context, 40)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.usb,
                size: _getResponsiveSize(context, 80),
                color: AppColors.primary,
              ),
              SizedBox(height: _getResponsiveSize(context, 24)),
              Text(
                _isLoading
                    ? 'USB 기기를 검색하고 있습니다'
                    : _isSaving
                        ? '기기를 등록하고 있습니다'
                        : '${_devices.length}개의 USB 기기가 발견되었습니다',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 32),
                  fontVariations: <FontVariation>[FontVariation('wght', 600)],
                  fontFamily: AppTextStyles.bodyFontFamily,
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 12)),
              Text(
                _isLoading
                    ? 'AF-50U 음주측정기를 찾고 있습니다.'
                    : _isSaving
                        ? '잠시만 기다려주세요.'
                        : 'AF-50U 기기를 선택하여 등록하세요.',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 26),
                  color: const Color(0xFF757575),
                  fontFamily: AppTextStyles.bodyFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isLoading || _isSaving) ...[
                SizedBox(height: _getResponsiveSize(context, 32)),
                const CircularProgressIndicator(),
              ],
              if (!_isLoading && !_isSaving && _devices.isNotEmpty) ...[
                SizedBox(height: _getResponsiveSize(context, 40)),
                Expanded(
                  child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final deviceName =
                          device.productName?.isNotEmpty == true
                              ? device.productName!
                              : device.manufacturerName?.isNotEmpty == true
                                  ? device.manufacturerName!
                                  : 'USB 기기 ${index + 1}';
                      final vid = device.vid?.toRadixString(16).toUpperCase() ?? '-';
                      final pid = device.pid?.toRadixString(16).toUpperCase() ?? '-';
                      return Card(
                        margin: EdgeInsets.only(
                            bottom: _getResponsiveSize(context, 16)),
                        child: ListTile(
                          leading: const Icon(
                            Icons.usb,
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
                            'VID: 0x$vid  PID: 0x$pid',
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: _getResponsiveSize(context, 24),
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectDevice(device),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!_isLoading && !_isSaving && _devices.isEmpty) ...[
                SizedBox(height: _getResponsiveSize(context, 40)),
                ElevatedButton.icon(
                  onPressed: _refreshDevices,
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
