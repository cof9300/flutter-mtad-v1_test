import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_template/services/fcm_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/providers/notifier/rich_text_notifier.dart';
import 'package:flutter_template/auth/screen/splash_screen.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_template/features/measurement/model/blood_pressure_result.dart';
import 'package:flutter_template/features/measurement/model/height_weight_result.dart';
import 'package:flutter_template/features/measurement/screen/blood_pressure_result_screen_new.dart';
import 'package:flutter_template/features/measurement/screen/height_weight_result_screen.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/providers/notifier/app_lock_notifier.dart';
import 'package:media_kit/media_kit.dart';

/// 기기에 맞는 허용 방향 목록을 반환한다.
/// G10: portraitDown 고정 / 그 외: 양쪽 모두 허용
List<DeviceOrientation> get preferredOrientations => DeviceConfig().isG10
    ? [DeviceOrientation.portraitDown]
    : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];

class OrientationRouteObserver extends RouteObserver<ModalRoute> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    SystemChrome.setPreferredOrientations(preferredOrientations);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    SystemChrome.setPreferredOrientations(preferredOrientations);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    SystemChrome.setPreferredOrientations(preferredOrientations);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    SystemChrome.setPreferredOrientations(preferredOrientations);
  }
}

final routeObserver = OrientationRouteObserver();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    MediaKit.ensureInitialized();

    // 기기 감지 (G10 · Galaxy Tab A9+) 후 방향 고정
    await DeviceConfig().initialize();
    SystemChrome.setPreferredOrientations(preferredOrientations);

    await dotenv.load(fileName: "assets/.env");

    FlutterErrorLogger.initialize();
    FlutterErrorLogger.system(
      '앱 시작',
      errorCode: 'SYS-006',
      severity: 'INFO',
    );

    await ServiceLocator().init();

    // FCM 초기화 — 키오스크 ID를 전달해 토큰 등록 시 deviceId로 사용
    try {
      final fcmKioskId = await ServiceLocator().kioskIdStorage.getKioskId();
      await FcmService().initialize(kioskId: fcmKioskId);
    } catch (e) {
      FlutterErrorLogger.logError('[FCM] 초기화 실패', e);
    }

    final savedKioskId = await ServiceLocator().kioskIdStorage.getKioskId();
    if (savedKioskId != null && savedKioskId.isNotEmpty) {
      FlutterErrorLogger.setKioskId(savedKioskId);
      FlutterErrorLogger.system('저장된 장치 ID 로드 완료: $savedKioskId');
    }

    // 재부팅 성공 감지: Kotlin에서 재부팅 직전 저장한 플래그를 읽어 로그 전송 후 삭제
    try {
      final prefs = await SharedPreferences.getInstance();
      final rebootType = prefs.getString('last_reboot_type');
      if (rebootType != null) {
        await prefs.remove('last_reboot_type');
        if (rebootType == 'auto') {
          FlutterErrorLogger.system(
            '자동 재부팅 후 앱 시작 완료 (재부팅 성공)',
            errorCode: 'SYS-014',
            severity: 'INFO',
          );
        } else if (rebootType == 'manual') {
          FlutterErrorLogger.system(
            '수동 재부팅 후 앱 시작 완료 (재부팅 성공)',
            errorCode: 'SYS-015',
            severity: 'INFO',
          );
        }
      }
    } catch (_) {}

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    await SystemChrome.setPreferredOrientations(preferredOrientations);

    // 이미지 캐시 상한을 앱 시작 시점에 제한 (기본값 100개/100MB는 저사양 기기에서 과도함)
    PaintingBinding.instance.imageCache.maximumSize = 20;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;

    runApp(
      ProviderScope(
        overrides: [
          richTextNotifierProvider.overrideWith((ref) {
            return RichTextNotifier(ServiceLocator().richTextStorageService);
          }),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // 비동기 에러 핸들링
    FlutterErrorLogger.logError('[시스템] 비동기 오류', error, stack);
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  StreamSubscription? _bloodPressureSubscription;
  StreamSubscription? _heightWeightSubscription;
  StreamSubscription<bool>? _fcmLockSubscription;

  // 동시 다발 측정 결과 플러드 방지 디바운서 (InBody 오프라인 저장 데이터 일괄 전송 대응)
  // 2초 이내 복수 결과가 들어오면 마지막 것만 처리한다.
  static const _kResultDebounce = Duration(seconds: 2);
  Timer? _bpDebounceTimer;
  BloodPressureResult? _pendingBpResult;
  Timer? _hwDebounceTimer;
  HeightWeightResult? _pendingHwResult;

  // static: 앱 kill 후 재실행 시에만 초기화되므로 "최초 1회" 보장
  static bool _startupDelayApplied = false;

  // _startupChecked: 딜레이 설정값을 읽었는지 여부 (읽기 전엔 빈 화면 유지)
  // _isInStartupDelay: 딜레이 진행 중 — 두 값 모두 false여야 SplashScreen으로 전환
  bool _startupChecked = false;
  bool _isInStartupDelay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(preferredOrientations);
    _startGlobalMeasurementListener();
    _startGlobalHeightWeightListener();

    // 앱 시작 시 appLockProvider를 즉시 초기화 (lazy 초기화 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLockProvider);
    });

    // FCM 잠금 명령 스트림 구독 — 포어그라운드에서 즉시 적용
    _fcmLockSubscription = FcmService().lockCommandStream.listen((shouldLock) {
      ref.read(appLockProvider.notifier).setLocked(shouldLock);
    });

    if (!_startupDelayApplied) {
      _startupDelayApplied = true;
      // 첫 번째 프레임 렌더 후 딜레이 확인 — 그 전까지는 _AppStartingScreen 표시
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyStartupDelay());
    } else {
      // 핫리로드/위젯 재생성: 딜레이 없이 즉시 SplashScreen 표시
      _startupChecked = true;
    }
  }

  Future<void> _applyStartupDelay() async {
    final delay = await ServiceLocator().appStartDelayService.getDelaySeconds();
    if (!mounted) return;

    if (delay > 0) {
      FlutterErrorLogger.system('[시작딜레이] 앱 시작 동기화 ${delay}초 시작');
      setState(() {
        _isInStartupDelay = true;
        _startupChecked = true;
      });
      await Future.delayed(Duration(seconds: delay));
      if (!mounted) return;
      setState(() => _isInStartupDelay = false);
      FlutterErrorLogger.system('[시작딜레이] 완료 — 정상 시작');
    } else {
      setState(() => _startupChecked = true);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setPreferredOrientations(preferredOrientations);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      // 백그라운드에서 수신된 FCM 잠금 명령을 적용한다.
      FcmService().applyPendingLockCommand();
    }
  }

  void _startGlobalMeasurementListener() {
    _bloodPressureSubscription =
        MeasurementListener().bloodPressureStream.listen((result) {
      if (_isInStartupDelay) return;

      // 이전 pending 결과가 있으면 새 결과로 교체 (플러드 시 마지막 결과만 사용)
      if (_pendingBpResult != null) {
        FlutterErrorLogger.logInfo(
          '[측정결과] 혈압 결과 중복 수신 — 이전 결과 폐기 후 최신 결과로 교체 '
          '(${_pendingBpResult!.systolic}/${_pendingBpResult!.diastolic} → ${result.systolic}/${result.diastolic})',
        );
      }
      _pendingBpResult = result;

      // 타이머 재시작: 2초 내 추가 결과가 없으면 최신 결과를 화면에 표시
      _bpDebounceTimer?.cancel();
      _bpDebounceTimer = Timer(_kResultDebounce, () {
        final pending = _pendingBpResult;
        _pendingBpResult = null;
        if (pending == null) return;
        if (navigatorKey.currentContext == null ||
            navigatorKey.currentState == null) return;
        FlutterErrorLogger.logInfo(
          '[측정결과] 혈압 결과 화면 표시 (디바운스 완료): ${pending.systolic}/${pending.diastolic}/${pending.pulse}',
        );
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => BloodPressureResultScreenNew(result: pending),
          ),
        );
      });
    });
  }

  void _startGlobalHeightWeightListener() {
    _heightWeightSubscription =
        MeasurementListener().heightWeightStream.listen((result) {
      if (_isInStartupDelay) return;

      if (_pendingHwResult != null) {
        FlutterErrorLogger.logInfo(
          '[측정결과] 신장체중 결과 중복 수신 — 이전 결과 폐기 후 최신 결과로 교체',
        );
      }
      _pendingHwResult = result;

      _hwDebounceTimer?.cancel();
      _hwDebounceTimer = Timer(_kResultDebounce, () {
        final pending = _pendingHwResult;
        _pendingHwResult = null;
        if (pending == null) return;
        if (navigatorKey.currentContext == null ||
            navigatorKey.currentState == null) return;
        FlutterErrorLogger.logInfo(
          '[측정결과] 신장체중 결과 화면 표시 (디바운스 완료)',
        );
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => HeightWeightResultScreen(result: pending),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloodPressureSubscription?.cancel();
    _heightWeightSubscription?.cancel();
    _fcmLockSubscription?.cancel();
    _bpDebounceTimer?.cancel();
    _hwDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Flutter Template',
      locale: locale,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('zh'),
        Locale('vi'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // 딜레이 확인 전이거나 딜레이 진행 중이면 전용 화면으로 덮어씌움
        // builder는 setState에 즉시 반응하므로 home: prop 교체 방식보다 확실하게 동작
        if (!_startupChecked || _isInStartupDelay) {
          return const _AppStartingScreen();
        }
        return child ?? const SizedBox();
      },
      home: const SplashScreen(),
    );
  }
}

class _AppStartingScreen extends StatelessWidget {
  const _AppStartingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
            Text(
              '앱 시작 중입니다.',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 24,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 600),
                ],
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocaleTestPage extends ConsumerWidget {
  const LocaleTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(l10n.appTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Current Locale: ${locale.languageCode}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ref.read(localeProvider.notifier).toggleLocale();
              },
              child: const Text('Toggle Language (EN ⇄ KO)'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.read(localeProvider.notifier).changeTemporaryLocale(
                          const Locale('en'),
                        );
                  },
                  child: const Text('English'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.read(localeProvider.notifier).changeTemporaryLocale(
                          const Locale('ko'),
                        );
                  },
                  child: const Text('한국어'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
