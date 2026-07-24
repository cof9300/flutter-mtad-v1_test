import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

/// 앱 시작 시 [initialize]를 호출해 기기 정보를 한 번만 감지한다.
/// 이후 어디서든 [DeviceConfig()] 로 싱글톤에 접근할 수 있다.
class DeviceConfig {
  static final DeviceConfig _instance = DeviceConfig._();
  DeviceConfig._();
  factory DeviceConfig() => _instance;

  /// Samsung Galaxy Tab A9+ (SM-X210 Wi-Fi / SM-X216 5G)
  /// 1920×1200 해상도, DPR ≈ 2.0 → physicalWidth ≈ 1200 (키오스크 범위와 겹침)
  static const List<String> _galaxyTabA9PlusModels = ['SM-X210', 'SM-X216'];

  /// G10 시리즈: 항상 portraitDown 으로 장착되며 video_player 를 사용한다.
  static const String _g10Keyword = 'G10';

  bool isG10 = false;
  bool isGalaxyTabA9Plus = false;

  Future<void> initialize() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final model = info.model.toUpperCase();
      isG10 = model.contains(_g10Keyword);
      isGalaxyTabA9Plus =
          _galaxyTabA9PlusModels.any((m) => model.contains(m));
    } catch (_) {
      isG10 = false;
      isGalaxyTabA9Plus = false;
    }
  }

  /// 물리 픽셀 너비 기반 "대형 키오스크" 판별.
  /// - Galaxy Tab A9+ / G10 은 키오스크로 분류하지 않는다.
  /// - physicalWidth = logicalWidth × devicePixelRatio
  bool isLargeKiosk(BuildContext context) {
    if (isG10 || isGalaxyTabA9Plus) return false;
    final mq = MediaQuery.of(context);
    final physicalWidth = mq.size.width * mq.devicePixelRatio;
    return physicalWidth >= 900 && physicalWidth <= 1300;
  }

  /// 결과 화면에서 영상 위 추가 여백이 필요한 "태블릿 폼팩터" 판별.
  /// - Galaxy Tab A9+ 는 명시적으로 태블릿으로 처리한다.
  /// - 그 외: shortestSide ≥ 650 && DPR ≤ 1.5 휴리스틱.
  bool isTabletSized(BuildContext context) {
    if (isGalaxyTabA9Plus) return true;
    final mq = MediaQuery.of(context);
    return mq.size.shortestSide >= 650 && mq.devicePixelRatio <= 1.5;
  }
}
