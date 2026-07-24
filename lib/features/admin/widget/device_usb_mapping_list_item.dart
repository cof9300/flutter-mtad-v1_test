import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/device_type_helper.dart';
import 'package:flutter_template/data/model/device.dart';
import 'package:flutter_template/features/admin/widget/usb_port_selection_dialog.dart';

class DeviceUsbMappingListItem extends ConsumerWidget {
  final Device device;

  const DeviceUsbMappingListItem({
    super.key,
    required this.device,
  });

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  void _showUsbPortSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UsbPortSelectionDialog(device: device),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = _getResponsiveSize(context, 32);
    final subFontSize = _getResponsiveSize(context, 24);
    final itemHeight = _getResponsiveSize(context, 100);
    final displayName = DeviceTypeHelper.getDeviceTypeName(context, device.type);

    return GestureDetector(
      onTap: () => _showUsbPortSelection(context),
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
              offset: Offset(0, 2),
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
                borderRadius:
                    BorderRadius.circular(_getResponsiveSize(context, 12)),
              ),
              child: Center(
                child: Icon(
                  Icons.medical_services,
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
                    color: Color(0xFF111111),
                  ),
                  children: [
                    TextSpan(text: displayName),
                    TextSpan(
                      text: ' (${device.name})',
                      style: TextStyle(
                        fontSize: subFontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 400),
                        ],
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: _getResponsiveSize(context, 40),
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }
}

