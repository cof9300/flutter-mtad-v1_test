import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/providers/notifier/device_list_notifier.dart';
import 'package:flutter_template/features/admin/widget/device_usb_mapping_list_item.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UsbDeviceRegistrationScreen extends ConsumerWidget {
  const UsbDeviceRegistrationScreen({super.key});

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);
    final screenSize = MediaQuery.of(context).size;
    final topPadding = _getResponsiveSize(context, 20);
    final horizontalPadding = _getResponsiveSize(context, 80);
    final titleFontSize = _getResponsiveSize(context, 48);
    final iconSize = (screenSize.height * 0.08).clamp(40.0, 60.0);

    return CommonLayout(
      disableClockAdminEntry: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: topPadding, top: topPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(_getResponsiveSize(context, 8)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/keypad-back.svg',
                        width: iconSize * 1.07,
                        height: iconSize * 1.07,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 60)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'USB 기기 등록',
                  style: TextStyle(
                    fontFamily: AppTextStyles.titleFontFamily,
                    fontSize: titleFontSize,
                    fontVariations: <FontVariation>[FontVariation('wght', 900)],
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 40)),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: _getResponsiveSize(context, 80),
                            color: Colors.grey,
                          ),
                          SizedBox(height: _getResponsiveSize(context, 20)),
                          Text(
                            '등록 가능한 기기가 없습니다',
                            style: TextStyle(
                              fontFamily: AppTextStyles.bodyFontFamily,
                              fontSize: _getResponsiveSize(context, 32),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return DeviceUsbMappingListItem(device: device);
                      },
                    ),
            ),
            SizedBox(height: _getResponsiveSize(context, 40)),
          ],
        ),
      ),
    );
  }
}

