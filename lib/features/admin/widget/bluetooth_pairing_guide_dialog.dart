import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/features/admin/widget/bluetooth_scan_dialog.dart';
import 'package:flutter_template/features/admin/widget/alco_bluetooth_scan_screen.dart';
import 'package:flutter_template/features/admin/widget/alco_usb_setup_screen.dart';

class BluetoothPairingGuideDialog extends StatelessWidget {
  final String deviceType;
  final String deviceName;

  const BluetoothPairingGuideDialog({
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

  String _getPairingGuideMessage(String deviceType) {
    switch (deviceType.toUpperCase()) {
      case 'BP':
        return '기기 오른쪽 하단 [페어링 버튼]을 3초간 눌러\n'
            '블루투스 모드를 활성화 시켜주세요.';
      case 'AL':
        return 'AF-50AD(블루투스) 또는 AF-50U(USB) 중\n'
            '연결 방식을 선택해주세요.';
      default:
        return '기기의 블루투스 페어링 모드를\n'
            '활성화 시켜주세요.';
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    if (deviceType.toUpperCase() == 'AL') {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 32),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AlcoBluetoothScanScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(
            '블루투스 (AF-50AD)',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 28),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AlcoUsbSetupScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'USB (AF-50U)',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 28),
            ),
          ),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          '취소',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 32),
          ),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BluetoothScanScreen(
                deviceType: deviceType,
                deviceName: deviceName,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: Text(
          '연결하기',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 32),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(_getResponsiveSize(context, 40)),
      content: SizedBox(
        width: _getResponsiveSize(context, 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  deviceType.toUpperCase() == 'AL'
                      ? Icons.sensors
                      : Icons.bluetooth,
                  size: _getResponsiveSize(context, 80),
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 24)),
            Text(
              '$deviceName 연결',
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 28),
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                color: Colors.black,
                fontFamily: AppTextStyles.bodyFontFamily,
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            Text(
              _getPairingGuideMessage(deviceType),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 22),
                height: 1.5,
                color: const Color(0xFF757575),
                fontFamily: AppTextStyles.bodyFontFamily,
              ),
            ),
          ],
        ),
      ),
      actions: _buildActions(context),
    );
  }
}

