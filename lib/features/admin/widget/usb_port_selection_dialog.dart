import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/device_type_helper.dart';
import 'package:flutter_template/data/model/device.dart';
import 'package:flutter_template/data/model/usb_device_info.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';
import 'package:flutter_template/providers/notifier/usb_devices_notifier.dart';
import 'package:flutter_template/providers/notifier/device_usb_mappings_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_notifier.dart';
import 'package:flutter_template/config/service_locator.dart';

class UsbPortSelectionDialog extends ConsumerStatefulWidget {
  final Device device;

  const UsbPortSelectionDialog({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<UsbPortSelectionDialog> createState() =>
      _UsbPortSelectionDialogState();
}

class _UsbPortSelectionDialogState
    extends ConsumerState<UsbPortSelectionDialog> {
  bool _isRefreshing = false;
  UsbDeviceInfo? _existingMapping;
  // portName → 이미 할당된 다른 기기 타입 (예: 'BP', 'AL').
  // portName은 USB 재삽입 후 변경될 수 있어, 로드 시 현재 연결된 기기 목록과
  // 대조(reconcile)하여 최신 portName으로 갱신한다.
  Map<String, String> _otherDeviceMappings = {};

  @override
  void initState() {
    super.initState();
    // refresh 먼저 완료 후 매핑 로드 — provider에 최신 기기 목록이 있어야
    // portName reconciliation이 정확하게 동작한다.
    _refreshDevices().then((_) => _loadExistingMapping());
  }

  Future<void> _loadExistingMapping() async {
    final allMappings =
        await ServiceLocator().deviceUsbMappingStorage.getMappings();

    final myType = widget.device.type.toUpperCase();
    final currentDevices = ref.read(usbDevicesProvider);

    // 이 키오스크에 실제로 설정된 기기 타입만 사용한다.
    // 스토리지에 과거 설정의 stale 매핑(예: 이 키오스크에서 쓰지 않는 AL)이
    // 남아있어도 "다른 기기 사용중" 뱃지에 반영되지 않도록 필터링한다.
    final configuredTypes =
        ref.read(deviceListProvider).map((d) => d.type.toUpperCase()).toSet();
    final activeMappings = allMappings
        .where((m) => configuredTypes.contains(m.deviceType.toUpperCase()))
        .toList();

    // 포트 귀속은 저장된 portName과 현재 기기 portName의 "정확 일치"로만 결정한다.
    //
    // 인바디(BP)와 음주(AL)가 동일 FTDI VID/PID(1027:24577)를 공유하는 현장에서는
    // VID/PID만으로 두 기기를 구분할 수 없다. 과거에는 VID/PID fallback으로 빠진
    // 기기가 다른 기기의 포트를 가로채(예: 음주가 빠졌는데 BP 포트를 "AL 사용중"으로
    // 표시) 잘못된 뱃지가 떴다.
    //
    // 대신 런타임(MeasurementListener/AlcoUsbService)이 실제 연결에 성공한 포트
    // 경로를 저장소에 자동 반영(write-back)하므로, 재삽입으로 경로가 바뀌어도
    // 기기가 재연결되면 저장 portName이 최신으로 유지된다. 따라서 정확 일치만으로
    // 충분하며, 빠진 기기는 어떤 포트도 차지하지 않는다.

    // deviceType → 저장된 portName. 실제 뱃지/등록 표시는 아래에서
    // "현재 연결된 포트와 일치하는지"로만 판정하므로, 빠진 기기는 표시되지 않는다.
    final resolvedPorts = <String, String>{};
    DeviceUsbMapping? mine;
    for (final m in activeMappings) {
      final type = m.deviceType.toUpperCase();
      if (type == myType) mine = m;
      resolvedPorts[type] = m.portName;
    }

    final myPortName = resolvedPorts[myType];

    // "다른 기기 사용중" 뱃지는 실제로 현재 연결된 포트에만 표시한다.
    final connectedPortNames = currentDevices.map((d) => d.portName).toSet();
    final others = <String, String>{};
    for (final m in activeMappings) {
      final type = m.deviceType.toUpperCase();
      if (type == myType) continue;
      final portName = resolvedPorts[type];
      if (portName != null &&
          portName.isNotEmpty &&
          connectedPortNames.contains(portName)) {
        others[portName] = type;
      }
    }

    if (!mounted) return;
    setState(() {
      _otherDeviceMappings = others;
      _existingMapping = (mine != null && myPortName != null)
          ? UsbDeviceInfo(
              portName: myPortName,
              vid: mine.vid,
              pid: mine.pid,
              deviceName: myPortName,
            )
          : null;
    });
  }

  Future<void> _refreshDevices() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ServiceLocator().usbService.getAvailableDevices();
      await Future.delayed(Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _saveMapping(UsbDeviceInfo usbDevice) async {
    int baudRate = 38400;

    final type = widget.device.type.toUpperCase();
    if (type == 'AL' || type == 'ST') {
      baudRate = 115200;
    } else if (type == 'HS') {
      baudRate = 9600;
    } else if (type == 'BP') {
      final deviceName = widget.device.name.toLowerCase();
      final isBp250 = deviceName.contains('bp250') ||
          deviceName.contains('bp210') ||
          deviceName.contains('accuniq') ||
          deviceName.contains('250');
      if (deviceName.contains('인바디') || deviceName.contains('inbody')) {
        baudRate = 9600;
      } else if (isBp250) {
        // 셀바스 ACCUNIQ BP210: 실기기는 38400/1stop/R1 포맷으로 동작(스펙상 4800이나
        // 현장 실측 결과 4800에서는 통신이 깨짐). 헬스체크만 버전조회(0x56) 방식 사용.
        baudRate = 38400;
      } else if (deviceName.contains('셀바스') || deviceName.contains('celvas')) {
        baudRate = 38400;
      }
    }

    final mapping = DeviceUsbMapping(
      deviceType: widget.device.type,
      portName: usbDevice.portName,
      vid: usbDevice.vid,
      pid: usbDevice.pid,
      baudRate: baudRate,
    );

    await ref.read(deviceUsbMappingsProvider.notifier).addMapping(mapping);

    if (mounted) {
      final displayName =
          DeviceTypeHelper.getDeviceTypeName(context, widget.device.type);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$displayName (${widget.device.name})와(과) ${usbDevice.displayName} 연결 완료',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeMapping() async {
    await ref
        .read(deviceUsbMappingsProvider.notifier)
        .removeMapping(widget.device.type);

    if (mounted) {
      final displayName =
          DeviceTypeHelper.getDeviceTypeName(context, widget.device.type);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$displayName (${widget.device.name}) 연결 해제 완료',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showRemoveConfirmDialog() {
    showDialog(
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
          'USB 포트 연결을 해제하시겠습니까?',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: _getResponsiveSize(context, 24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 22),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMapping();
            },
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
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final usbDevices = ref.watch(usbDevicesProvider);

    // USB 기기 목록이 바뀔 때마다(삽입/제거) portName reconciliation 재실행 →
    // 모달을 닫았다 열지 않아도 실시간으로 연결 상태가 반영된다.
    ref.listen(usbDevicesProvider, (_, __) => _loadExistingMapping());
    final displayName =
        DeviceTypeHelper.getDeviceTypeName(context, widget.device.type);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USB 포트 선택',
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
                        text: ' (${widget.device.name})',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 20),
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 400),
                          ],
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: _getResponsiveSize(context, 700),
        child: usbDevices.isEmpty
            ? _buildEmptyState(context)
            : _buildDeviceList(context, usbDevices),
      ),
      actions: [
        if (_existingMapping != null)
          TextButton.icon(
            onPressed: _showRemoveConfirmDialog,
            icon: Icon(
              Icons.link_off,
              size: _getResponsiveSize(context, 24),
              color: Colors.red,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            label: Text(
              '연결 해제',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 24),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 600),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 24),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _refreshDevices,
          icon: Icon(Icons.refresh, size: _getResponsiveSize(context, 24)),
          label: Text(
            '새로고침',
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
            Icons.usb_off,
            size: _getResponsiveSize(context, 80),
            color: Colors.grey,
          ),
          SizedBox(height: _getResponsiveSize(context, 20)),
          Text(
            'USB 포트가 감지되지 않습니다',
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: _getResponsiveSize(context, 28),
              fontVariations: <FontVariation>[
                FontVariation('wght', 600),
              ],
              color: Color(0xFF111111),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _getResponsiveSize(context, 12)),
          Text(
            'USB 기기를 연결한 후\n새로고침 버튼을 눌러주세요',
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

  Widget _buildDeviceList(BuildContext context, List<UsbDeviceInfo> devices) {
    final allDevices = <UsbDeviceInfo>[...devices]
      ..sort((a, b) => a.portName.compareTo(b.portName));

    return ListView.builder(
      shrinkWrap: true,
      itemCount: allDevices.length,
      itemBuilder: (context, index) {
        final device = allDevices[index];
        // reconcile 후 최신 portName 기준으로 매칭한다.
        final isRegistered = _existingMapping != null &&
            _existingMapping!.portName == device.portName;

        // 이 포트가 다른 기기에 이미 할당돼 있는지 확인
        final otherDeviceType = _otherDeviceMappings[device.portName];
        final isUsedByOther = otherDeviceType != null;

        return Container(
          margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 12)),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRegistered
                  ? AppColors.primary
                  : isUsedByOther
                      ? Colors.orange.withValues(alpha: 0.6)
                      : Colors.grey.withValues(alpha: 0.3),
              width: isRegistered ? 2 : 1,
            ),
            borderRadius:
                BorderRadius.circular(_getResponsiveSize(context, 12)),
            color: isUsedByOther && !isRegistered
                ? Colors.orange.withValues(alpha: 0.04)
                : null,
          ),
          child: ListTile(
            leading: Icon(
              Icons.usb,
              color: isRegistered
                  ? AppColors.primary
                  : isUsedByOther
                      ? Colors.orange
                      : Colors.grey,
              size: _getResponsiveSize(context, 32),
            ),
            title: Row(
              children: [
                Text(
                  device.displayName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 26),
                    fontVariations: <FontVariation>[
                      FontVariation('wght', isRegistered ? 700 : 500),
                    ],
                    color: Colors.black,
                  ),
                ),
                if (isUsedByOther) ...[
                  SizedBox(width: _getResponsiveSize(context, 8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSize(context, 10),
                      vertical: _getResponsiveSize(context, 3),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(_getResponsiveSize(context, 6)),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      otherDeviceType,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: _getResponsiveSize(context, 18),
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: _getResponsiveSize(context, 4)),
                Text(
                  device.portLabel,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 20),
                    color: Color(0xFF444444),
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 500),
                    ],
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 2)),
                Text(
                  device.vidPidString,
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: _getResponsiveSize(context, 18),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 4)),
                if (isRegistered)
                  Text(
                    '현재 등록된 포트',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: _getResponsiveSize(context, 18),
                      color: AppColors.primary,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 600),
                      ],
                    ),
                  ),
                if (isUsedByOther && !isRegistered)
                  Text(
                    '$otherDeviceType 장치에 이미 연결됨',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: _getResponsiveSize(context, 18),
                      color: Colors.orange.shade700,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 500),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              isRegistered ? Icons.check_circle : Icons.chevron_right,
              color: isRegistered ? AppColors.primary : Colors.grey,
              size: _getResponsiveSize(context, 32),
            ),
            onTap: () => _saveMapping(device),
          ),
        );
      },
    );
  }
}
