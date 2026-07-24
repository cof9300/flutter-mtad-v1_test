import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/device_type_helper.dart';
import 'package:flutter_template/data/model/device_bluetooth_mapping.dart';
import 'package:flutter_template/providers/notifier/device_bluetooth_mappings_notifier.dart';
import 'package:flutter_template/features/admin/widget/bluetooth_pairing_guide_dialog.dart';

class BluetoothDeviceManagementDialog extends ConsumerStatefulWidget {
  final String deviceType;
  final String deviceName;

  const BluetoothDeviceManagementDialog({
    super.key,
    required this.deviceType,
    required this.deviceName,
  });

  @override
  ConsumerState<BluetoothDeviceManagementDialog> createState() =>
      _BluetoothDeviceManagementDialogState();
}

class _BluetoothDeviceManagementDialogState
    extends ConsumerState<BluetoothDeviceManagementDialog> {
  List<DeviceBluetoothMapping> get _registeredDevices {
    final mappings = ref.watch(deviceBluetoothMappingsProvider);
    return mappings
        .where((m) => m.deviceType == widget.deviceType)
        .toList();
  }

  Future<void> _handleRemove(DeviceBluetoothMapping mapping) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '연결 해제',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 28),
            fontVariations: <FontVariation>[
              FontVariation('wght', 700),
            ],
          ),
        ),
        content: Text(
          '${mapping.deviceName} 연결을 해제하시겠습니까?',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 22),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              '해제',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 22),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 600),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(deviceBluetoothMappingsProvider.notifier).removeMapping(mapping.deviceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${mapping.deviceName} 연결이 해제되었습니다.',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 24),
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showPairingGuide() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => BluetoothPairingGuideDialog(
        deviceType: widget.deviceType,
        deviceName: widget.deviceName,
      ),
    );
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = DeviceTypeHelper.getDeviceTypeName(context, widget.deviceType);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '블루투스 기기 관리',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 32),
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 8)),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: _getResponsiveSize(context, 24),
                      color: AppColors.primary,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 600),
                      ],
                    ),
                    children: [
                      TextSpan(text: displayName),
                      TextSpan(
                        text: ' (${widget.deviceName})',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 20),
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 400),
                          ],
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: _getResponsiveSize(context, 700),
        child: _registeredDevices.isEmpty
            ? _buildEmptyState(context)
            : _buildDeviceList(context),
      ),
      actions: [
        // 기기가 등록되어 있지 않을 때만 기기 추가 버튼 표시 (종류별 1개만 허용)
        if (_registeredDevices.isEmpty)
          TextButton.icon(
            onPressed: _showPairingGuide,
            icon: Icon(
              Icons.add_circle_outline,
              size: _getResponsiveSize(context, 24),
              color: AppColors.primary,
            ),
            label: Text(
              '기기 추가',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 24),
                color: AppColors.primary,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '닫기',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_getResponsiveSize(context, 40)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: _getResponsiveSize(context, 80),
            color: Colors.grey,
          ),
          SizedBox(height: _getResponsiveSize(context, 20)),
          Text(
            '등록된 블루투스 기기가 없습니다',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 28),
              fontVariations: <FontVariation>[
                FontVariation('wght', 600),
              ],
              color: const Color(0xFF111111),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _getResponsiveSize(context, 12)),
          Text(
            '기기 추가 버튼을 눌러\n블루투스 기기를 등록해주세요',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 22),
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _registeredDevices.length,
      itemBuilder: (context, index) {
        final device = _registeredDevices[index];
        return Opacity(
          opacity: device.isEnabled ? 1.0 : 0.6,
          child: Container(
            margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 12)),
            decoration: BoxDecoration(
              border: Border.all(
                color: device.isEnabled ? AppColors.primary : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
            ),
            child: ListTile(
              leading: Icon(
                device.isEnabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: device.isEnabled ? AppColors.primary : Colors.grey,
                size: _getResponsiveSize(context, 32),
              ),
            title: Text(
              device.deviceName,
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 26),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: device.isEnabled ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: _getResponsiveSize(context, 4)),
                Text(
                  device.macAddress,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 20),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 4)),
                Text(
                  device.isEnabled ? '활성화됨' : '비활성화됨',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 18),
                    color: device.isEnabled ? AppColors.primary : Colors.grey,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: device.isEnabled,
                  onChanged: (value) async {
                    await ref
                        .read(deviceBluetoothMappingsProvider.notifier)
                        .toggleEnabled(device.deviceId);
                  },
                  activeColor: AppColors.primary,
                ),
                SizedBox(width: _getResponsiveSize(context, 4)),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: _getResponsiveSize(context, 28),
                    color: Colors.red,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _handleRemove(device),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
