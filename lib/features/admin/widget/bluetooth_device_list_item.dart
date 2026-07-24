import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/device_type_helper.dart';
import 'package:flutter_template/providers/notifier/device_bluetooth_mappings_notifier.dart';
import 'package:flutter_template/features/admin/widget/bluetooth_device_management_dialog.dart';

class BluetoothDeviceListItem extends ConsumerWidget {
  final String deviceType;
  final String deviceName;

  const BluetoothDeviceListItem({
    super.key,
    required this.deviceType,
    required this.deviceName,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _showManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BluetoothDeviceManagementDialog(
        deviceType: deviceType,
        deviceName: deviceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = _getResponsiveSize(context, 32);
    final subFontSize = _getResponsiveSize(context, 24);
    final itemHeight = _getResponsiveSize(context, 100);
    final displayName = DeviceTypeHelper.getDeviceTypeName(context, deviceType);
    final mappings = ref.watch(deviceBluetoothMappingsProvider);
    final registeredDevices = mappings.where((m) => m.deviceType == deviceType).toList();
    final registeredCount = registeredDevices.length;
    final enabledCount = registeredDevices.where((m) => m.isEnabled).length;

    return GestureDetector(
      onTap: () => _showManagementDialog(context),
      child: Container(
        height: itemHeight,
        margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSize(context, 40),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _getResponsiveSize(context, 60),
              height: _getResponsiveSize(context, 60),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
              ),
              child: Center(
                child: Icon(
                  Icons.bluetooth,
                  size: _getResponsiveSize(context, 32),
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 20)),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: fontSize,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                    color: const Color(0xFF111111),
                  ),
                  children: [
                    TextSpan(text: displayName),
                    TextSpan(
                      text: ' ($deviceName)',
                      style: TextStyle(
                        fontSize: subFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 400),
                        ],
                        color: const Color(0xFF666666),
                      ),
                    ),
                    if (registeredCount > 0)
                      TextSpan(
                        text: ' ($registeredCount개 등록됨, $enabledCount개 활성화)',
                        style: TextStyle(
                          fontSize: subFontSize,
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 400),
                          ],
                          color: enabledCount > 0 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: _getResponsiveSize(context, 40),
              color: const Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }
}
