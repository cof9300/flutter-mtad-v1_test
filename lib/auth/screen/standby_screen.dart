import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/measurement/service/measurement_listener.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/common_layout.dart';
import 'package:flutter_template/core/widget/progress_modal.dart';
import 'package:flutter_template/core/widget/error_modal.dart';
import 'package:flutter_template/core/widget/language_selection_modal.dart';
import 'package:flutter_template/core/widget/device_connection_modal.dart';
import 'package:flutter_template/core/widget/kiosk_id_required_modal.dart';
import 'package:flutter_template/data/model/response/kiosk_auth_response.dart';
import 'package:flutter_template/auth/screen/auth_screen.dart';
import 'package:flutter_template/config/service_locator.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/providers/notifier/header_title_notifier.dart';
import 'package:flutter_template/providers/notifier/header_logo_notifier.dart';
import 'package:flutter_template/providers/notifier/wait_content_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_notifier.dart';
import 'package:flutter_template/providers/notifier/mf_device_notifier.dart';
import 'package:flutter_template/providers/notifier/result_page_option_notifier.dart';
import 'package:flutter_template/providers/notifier/agreement_option_notifier.dart';
import 'package:flutter_template/providers/notifier/device_list_with_connection_notifier.dart';
import 'package:flutter_template/providers/notifier/last_bp_result_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_mode_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_measure_flag_notifier.dart';
import 'package:flutter_template/providers/notifier/guest_skip_auth_notifier.dart';
import 'package:flutter_template/providers/notifier/session_results_notifier.dart';
import 'package:flutter_template/providers/notifier/device_usb_mappings_notifier.dart';
import 'package:flutter_template/providers/notifier/device_bluetooth_mappings_notifier.dart';
import 'package:flutter_template/providers/notifier/usb_devices_notifier.dart';
import 'package:flutter_template/providers/notifier/user_auth_notifier.dart';
import 'package:flutter_template/core/utils/inbody_health_check.dart';
import 'package:flutter_template/core/utils/celvas_health_check.dart';
import 'package:flutter_template/providers/notifier/measure_id_notifier.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';
import 'package:flutter_template/data/model/device.dart';
import 'package:flutter_template/data/model/device_usb_mapping.dart';
import 'package:flutter_template/data/model/response/kiosk_option_response.dart';
import 'package:flutter_template/auth/widget/wait_content_area.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';
import 'package:flutter_template/main.dart' show routeObserver, preferredOrientations;
import 'package:flutter_template/features/measurement/screen/guest_phone_input_screen.dart';
import 'package:flutter_template/features/device/device_selection_screen.dart';
import 'package:flutter_template/auth/screen/auth_screen_with_birthday_gender.dart';
import 'package:flutter_template/core/utils/content_update_service.dart';
import 'package:flutter_template/core/utils/flutter_error_logger.dart';

class StandbyScreen extends ConsumerStatefulWidget {
  const StandbyScreen({super.key});

  @override
  ConsumerState<StandbyScreen> createState() => _StandbyScreenState();
}

class _StandbyScreenState extends ConsumerState<StandbyScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final _serviceLocator = ServiceLocator();
  bool _isLanguageButtonPressed = false;
  bool _didNavigateToOtherScreen = false;
  bool _isLanguageModalOpen = false;
  bool _isDeviceConnectionModalVisible = false;
  // 사용자가 연결 끊김 모달을 탭으로 닫으면 true.
  // 스탠바이 재진입 또는 모든 기기 재연결 전까지는 다시 표시하지 않는다.
  bool _deviceConnectionModalDismissed = false;
  bool _isKioskInitialized = false;
  bool _isKioskIdMissing = false;
  bool _isCheckingKioskId = false;
  bool _isKioskIdModalShown = false;
  bool _isSystemErrorModalShown = false;
  bool _isInvalidKioskIdModalShown = false;
  Timer? _memoryCleanupTimer;
  Timer? _initRetryTimer;
  Timer? _videoReinitTimer;
  int _videoPlayerKey = 0;

  /// USB 재삽입 자동 재연결: 직전 폴링 주기에서 본 VID/PID 집합.
  /// 새로 등장한 VID/PID가 저장된 매핑과 일치하면 자동으로 재연결한다.
  Set<String> _lastUsbVidPids = {};

  /// 대기화면이 최상위 라우트일 때 true. WaitContentArea 영상 재생 제어에 사용.
  final ValueNotifier<bool> _waitContentActive = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(preferredOrientations);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetAndInitialize();
    });
    _startMemoryCleanupTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    if (!_isLanguageModalOpen) {
      _didNavigateToOtherScreen = true;
      _waitContentActive.value = false; // 다른 화면으로 이동 → BGM 일시정지
    }
  }

  @override
  void didPopNext() async {
    if (_isLanguageModalOpen) {
      _isLanguageModalOpen = false;
      return;
    }
    if (!_didNavigateToOtherScreen) {
      return;
    }
    _didNavigateToOtherScreen = false;
    // 스탠바이 재진입 시 연결 끊김 모달 dismissed 상태 초기화 (다시 표시 가능하도록)
    _deviceConnectionModalDismissed = false;
    _waitContentActive.value = true; // 대기화면 복귀 → BGM 재개

    try {
      ref.read(userAuthProvider.notifier).clearUserAuth();
      ref.read(measureIdProvider.notifier).clearMeasureId();
      ref.read(localeProvider.notifier).resetToDefaultLocale();
      ref.read(guestModeProvider.notifier).clearGuestMode();
      ref.read(guestMeasureFlagProvider.notifier).clearGuestMeasureFlag();
      ref.read(guestSkipAuthProvider.notifier).clearSkipAuth();
      ref.read(lastBpResultProvider.notifier).clearResult();
      ref.read(sessionResultsProvider.notifier).clearResults();
    } catch (e) {}

    try {
      _serviceLocator.verifiedUserStorage.clearAll();
      _serviceLocator.guestPhoneStorage.clearPhoneNumber();
    } catch (e) {}

    if (!_isKioskInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted &&
              !_isInvalidKioskIdModalShown &&
              !_isKioskIdModalShown &&
              !_isSystemErrorModalShown) {
            _resetAndInitialize();
          }
        });
      });
    }
  }

  void _resetAndInitialize() {
    _initRetryTimer?.cancel();
    _initRetryTimer = null;
    setState(() {
      _isKioskIdMissing = false;
      _isCheckingKioskId = false;
      _isKioskIdModalShown = false;
      _isSystemErrorModalShown = false;
      _isInvalidKioskIdModalShown = false;
      _isKioskInitialized = false;
    });
    ref.read(guestModeProvider.notifier).clearGuestMode();
    ref.read(guestMeasureFlagProvider.notifier).clearGuestMeasureFlag();
    ref.read(guestSkipAuthProvider.notifier).clearSkipAuth();
    ref.read(sessionResultsProvider.notifier).clearResults();
    _checkKioskIdAndInitialize();
  }

  Future<void> _refreshContent() async {
    try {
      ref.read(waitContentProvider.notifier).clearContents();
    } catch (e) {}

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      ref.read(userAuthProvider.notifier).clearUserAuth();
      ref.read(measureIdProvider.notifier).clearMeasureId();
      ref.read(resultPageOptionProvider.notifier).clearResultPageOption();
      ref.read(headerLogoProvider.notifier).clearLogo();
      ref.read(headerTitleProvider.notifier).clearTitle();
      ref.read(agreementOptionProvider.notifier).clearAgreementOption();
      ref.read(guestModeProvider.notifier).clearGuestMode();
      ref.read(guestMeasureFlagProvider.notifier).clearGuestMeasureFlag();
      ref.read(guestSkipAuthProvider.notifier).clearSkipAuth();
      ref.read(lastBpResultProvider.notifier).clearResult();
      ref.read(sessionResultsProvider.notifier).clearResults();
    } catch (e) {}

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      PaintingBinding.instance.imageCache.maximumSize = 20;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
    } catch (e) {}

    if (mounted) {
      setState(() {
        _isKioskInitialized = false;
      });
      await _initializeKiosk();
    }
  }

  /// 초기화 실패 후 30초 뒤 자동 재시도한다.
  /// 네트워크 복구 시 앱 재시작 없이 정상 복귀되도록 한다.
  void _scheduleInitRetry() {
    _initRetryTimer?.cancel();
    _initRetryTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _isKioskInitialized) return;
      // 에러/진행 다이얼로그가 남아있으면 닫기
      try {
        Navigator.of(context).popUntil((route) => route is PageRoute);
      } catch (_) {}
      ProgressModal.hide();
      setState(() {
        _isSystemErrorModalShown = false;
        _isInvalidKioskIdModalShown = false;
        _isCheckingKioskId = false;
      });
      FlutterErrorLogger.system('키오스크 초기화 자동 재시도');
      _checkKioskIdAndInitialize();
    });
  }

  Future<void> _checkKioskIdAndInitialize() async {
    if (_isCheckingKioskId) {
      return;
    }

    if (_isKioskIdModalShown) {
      return;
    }

    if (_isSystemErrorModalShown) {
      return;
    }

    if (_isInvalidKioskIdModalShown) {
      return;
    }

    _isCheckingKioskId = true;

    try {
      final kioskId = await Config.getKioskId();

      if (kioskId == null || kioskId.isEmpty) {
        if (mounted && !_isKioskIdModalShown) {
          ProgressModal.hide();
          setState(() {
            _isKioskIdMissing = true;
            _isKioskIdModalShown = true;
            _isCheckingKioskId = false;
          });
          KioskIdRequiredModal.show(
            context,
            onClose: () {},
          );
        }
        return;
      }

      if (_isKioskIdMissing) {
        setState(() {
          _isKioskIdMissing = false;
          _isKioskIdModalShown = false;
        });
      }

      _isCheckingKioskId = false;
      await _initializeKiosk();
    } catch (e) {
      _isCheckingKioskId = false;
      print('Error checking Kiosk ID: $e');
    }
  }

  Future<void> _initializeKiosk() async {
    if (_isKioskInitialized) {
      return;
    }

    if (_isSystemErrorModalShown) {
      return;
    }

    if (_isInvalidKioskIdModalShown) {
      return;
    }

    try {
      print('========== Kiosk Initialization Start ==========');

      final kioskId = await Config.getKioskId();
      print('Kiosk ID: $kioskId');

      if (kioskId == null || kioskId.isEmpty) {
        return;
      }

      if (mounted) {
        ProgressModal.show(context);
      }

      print('Requesting kiosk authentication...');
      KioskAuthResponse authResponse;
      try {
        authResponse = await _serviceLocator.authRepository.kioskAuth(
          kioskId,
        );
      } catch (e) {
        print('Kiosk auth error: $e');
        if (mounted && !_isInvalidKioskIdModalShown) {
          ProgressModal.hide();
          setState(() {
            _isInvalidKioskIdModalShown = true;
          });
          InvalidKioskIdModal.show(context);
        }
        _scheduleInitRetry();
        return;
      }
      print('Auth response received');
      print('Token: ${authResponse.token}');

      print('Saving token...');
      await _serviceLocator.tokenStorage.saveToken(authResponse.token);
      print('Token saved successfully');

      FlutterErrorLogger.setKioskId(kioskId);
      FlutterErrorLogger.system('장치 ID 설정 완료: $kioskId');

      print('Checking for content updates...');
      try {
        ProgressModal.updateMessage(
          '이 과정은 최대 2분 정도 소요될 수 있습니다.',
          title: '변경사항을 적용하는 중입니다.',
        );
        final hasUpdate = await ContentUpdateService()
            .checkAndUpdateIfNeeded(
              authResponse.token,
              onProgress: (progress, message) {
                ProgressModal.updateMessage(
                  '이 과정은 최대 2분 정도 소요될 수 있습니다.',
                  title: '변경사항을 적용하는 중입니다.',
                );
              },
            );
        ProgressModal.updateMessage(null);
        if (hasUpdate) {
          print('Content updated successfully');
        } else {
          print('No content updates available');
        }
      } catch (e) {
        ProgressModal.updateMessage(null);
        print('Content update check failed: $e');
      }

      print('Clearing verified user data...');
      await _serviceLocator.verifiedUserStorage.clearAll();
      print('Verified user data cleared');

      print('Clearing guest phone number...');
      await _serviceLocator.guestPhoneStorage.clearPhoneNumber();
      print('Guest phone number cleared');

      print('Clearing measure ID...');
      ref.read(measureIdProvider.notifier).clearMeasureId();
      print('Measure ID cleared');

      print('Requesting kiosk options...');
      final currentKioskId = await Config.getKioskId() ?? '';
      var optionResponse = await _serviceLocator.authRepository.getKioskOption(
        authResponse.token,
      );
      print('Option response received');
      print('Options: $optionResponse');

      if (optionResponse.mode == 2) {
        optionResponse = KioskOptionResponse(
          kioskid: currentKioskId.isNotEmpty
              ? currentKioskId
              : optionResponse.kioskid,
          masking: optionResponse.masking,
          nextstep: optionResponse.nextstep,
          waittime: optionResponse.waittime,
          step: optionResponse.step,
          place: optionResponse.place,
          company: optionResponse.company,
          mode: optionResponse.mode,
          usecert: 2,
          resulttime: optionResponse.resulttime,
          screentime: optionResponse.screentime,
          certtime: optionResponse.certtime,
          sms: optionResponse.sms,
          demo: optionResponse.demo,
          facedetect: optionResponse.facedetect,
          voiceinfo: optionResponse.voiceinfo,
          resultprint: optionResponse.resultprint,
        );
        print('Mode is 2, usecert forced to 2');
      }

      print('Saving options...');
      await _serviceLocator.kioskOptionStorage.saveOption(optionResponse);
      print('Options saved successfully');

      print('Loading stored wait page options...');
      final waitPageOptionResponse =
          _serviceLocator.contentStorageService.getStoredWaitPageOption();

      if (waitPageOptionResponse != null) {
        print('Wait page options: $waitPageOptionResponse');
        print('Title: ${waitPageOptionResponse.title}');
        print('Logo: ${waitPageOptionResponse.logo}');
        print('Printer logo: ${waitPageOptionResponse.printerlogo}');
        print('CM count: ${waitPageOptionResponse.cm.length}');

        if (mounted && waitPageOptionResponse.title.isNotEmpty) {
          ref
              .read(headerTitleProvider.notifier)
              .setTitle(waitPageOptionResponse.title);
          print('Header title updated to: ${waitPageOptionResponse.title}');
        }

        if (mounted && waitPageOptionResponse.logo.isNotEmpty) {
          ref
              .read(headerLogoProvider.notifier)
              .setLogo(waitPageOptionResponse.logo);
          print('Header logo updated to: ${waitPageOptionResponse.logo}');
        }

        if (mounted && waitPageOptionResponse.cm.isNotEmpty) {
          ref
              .read(waitContentProvider.notifier)
              .setContents(waitPageOptionResponse.cm);
          print(
              'Wait content updated, count: ${waitPageOptionResponse.cm.length}');
        }
      } else {
        print('No stored wait page options found');
      }

      print('Requesting device list...');
      final deviceListResponse = await _serviceLocator.authRepository.getDevice(
        authResponse.token,
      );
      print('Device list response received');
      print('Device count: ${deviceListResponse.devices.length}');

      if (mounted && deviceListResponse.devices.isNotEmpty) {
        final allDevices = deviceListResponse.devices
            .map((deviceResponse) => Device.fromResponse(
                  deviceResponse.type,
                  deviceResponse.name,
                ))
            .toList();

        final mfDevice = allDevices
            .cast<Device?>()
            .firstWhere((d) => d!.type.toUpperCase() == 'MF', orElse: () => null);

        if (mfDevice != null) {
          ref.read(mfDeviceProvider.notifier).setDevice(mfDevice);
        } else {
          ref.read(mfDeviceProvider.notifier).clearDevice();
        }

        final devices = allDevices
            .where((d) => d.type.toUpperCase() != 'MF')
            .toList();

        ref.read(deviceListProvider.notifier).setDevices(devices);
        print('Device list updated, count: ${devices.length}');

        for (var device in devices) {
          print('Device: ${device.type} - ${device.name}');

          if (device.type.toUpperCase() == 'BP') {
            final existingMapping = await _serviceLocator
                .deviceUsbMappingStorage
                .getMappingByDeviceType(device.type);

            if (existingMapping != null) {
              int baudRate = 38400;
              final deviceName = device.name.toLowerCase();

              final isBp250 = deviceName.contains('bp250') ||
                  deviceName.contains('bp210') ||
                  deviceName.contains('accuniq') ||
                  deviceName.contains('250');
              if (deviceName.contains('인바디') || deviceName.contains('inbody')) {
                baudRate = 9600;
                print('인바디 감지 → baudRate: 9600');
              } else if (isBp250) {
                // BP210 실기기는 38400/R1로 동작 (4800에서는 통신 깨짐). 헬스체크만 버전조회 사용.
                baudRate = 38400;
                print('셀바스 BP210 감지 → baudRate: 38400');
              } else if (deviceName.contains('셀바스') ||
                  deviceName.contains('celvas')) {
                baudRate = 38400;
                print('셀바스 감지 → baudRate: 38400');
              }

              if (existingMapping.baudRate != baudRate) {
                print('BaudRate 업데이트: ${existingMapping.baudRate} → $baudRate');
                final updatedMapping = DeviceUsbMapping(
                  deviceType: existingMapping.deviceType,
                  portName: existingMapping.portName,
                  vid: existingMapping.vid,
                  pid: existingMapping.pid,
                  baudRate: baudRate,
                );
                await _serviceLocator.deviceUsbMappingStorage
                    .saveMapping(updatedMapping);
              }
            }
          }
        }
      }

      print('Loading stored result page options...');
      final resultPageOptionResponse =
          _serviceLocator.contentStorageService.getStoredResultPageOption();

      if (resultPageOptionResponse != null) {
        print('Masking: ${resultPageOptionResponse.masking}');
        print('CM count: ${resultPageOptionResponse.cm.length}');

        if (mounted) {
          ref
              .read(resultPageOptionProvider.notifier)
              .setResultPageOption(resultPageOptionResponse);
          print('Result page option updated');
        }
      } else {
        print('No stored result page options found');
      }

      print('Loading stored agreement options...');
      final agreementOptionResponse =
          _serviceLocator.contentStorageService.getStoredAgreementOption();

      if (agreementOptionResponse != null) {
        print('Agreement image 1: ${agreementOptionResponse.agreeimage1}');
        print('Agreement image 2: ${agreementOptionResponse.agreeimage2}');
        print('Agreement image 3: ${agreementOptionResponse.agreeimage3}');
        print('Agreement image 4: ${agreementOptionResponse.agreeimage4}');

        if (mounted) {
          ref
              .read(agreementOptionProvider.notifier)
              .setAgreementOption(agreementOptionResponse);
          print('Agreement option updated');
        }
      } else {
        print('No stored agreement options found');
      }

      final cachedAgreement = agreementOptionResponse;
      final needsAgreementRefresh = cachedAgreement == null ||
          cachedAgreement.agreeimage4.isEmpty;
      if (needsAgreementRefresh) {
        print('[Agreement] Cached data missing agreeimage4 - refreshing in background');
        unawaited(_refreshAgreementOption());
      }

      await MeasurementListener().restartListening();
      MeasurementListener().beginStartupClear();

      print('========== Kiosk Initialization Complete ==========');

      if (mounted) {
        ProgressModal.hide();
        _initRetryTimer?.cancel();
        _initRetryTimer = null;
        _isKioskInitialized = true;
        // 초기화 완료 후 1회만 연결 상태 확인 (이후 변화는 deviceConnectionStatusProvider가 5초마다 감지)
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _checkDeviceConnectionAndShowModal();
          }
        });
      }
    } catch (e, stackTrace) {
      print('========== Kiosk Initialization Error ==========');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace:');
      print(stackTrace);
      print('================================================');
      FlutterErrorLogger.logError('[시스템] 키오스크 초기화 오류', e, stackTrace);

      if (mounted &&
          !_isInvalidKioskIdModalShown &&
          !_isSystemErrorModalShown) {
        ProgressModal.hide();
        setState(() {
          _isSystemErrorModalShown = true;
        });
        ErrorModal.show(context);
      }
      _scheduleInitRetry();
    }
  }

  Future<void> _refreshAgreementOption() async {
    try {
      final token = await _serviceLocator.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        print('[Agreement] Skip refresh - no token');
        return;
      }
      final fresh = await _serviceLocator.authRepository
          .getAgreementOption(token)
          .timeout(const Duration(seconds: 10));
      await _serviceLocator.contentStorageService.saveAgreementOption(fresh);
      final reloaded =
          _serviceLocator.contentStorageService.getStoredAgreementOption();
      if (reloaded != null && mounted) {
        ref
            .read(agreementOptionProvider.notifier)
            .setAgreementOption(reloaded);
        print('[Agreement] Refreshed - agreeimage4=${reloaded.agreeimage4}');
      }
    } catch (e) {
      print('[Agreement] Refresh failed: $e');
    }
  }

  /// 새로 등장한 USB 기기(vidPid 집합)가 저장된 매핑과 일치하면 자동 재연결한다.
  /// - BP/InBody: MeasurementListener.restartDevice (VID/PID 기반으로 포트 재탐색)
  /// - AL: alcoUsbService.tryConnectSavedDevice (VID/PID + portName 기반 재연결)
  Future<void> _handleUsbDevicesReappeared(
    Set<String> newVidPids,
    List<DeviceUsbMapping> usbMappings,
  ) async {
    final reappeared = usbMappings
        .where((m) => newVidPids.contains('${m.vid}:${m.pid}'))
        .toList();
    if (reappeared.isEmpty) return;

    // 동일 VID/PID(FTDI)를 BP(인바디)와 AL(음주)이 공유하는 현장이 있다.
    // 이때는 상호 포트 배제가 성립하도록 BP를 먼저 재연결해 포트를 확정한 뒤
    // AL을 재연결한다(AL은 BP가 점유한 포트를 자동으로 제외).
    // → 순차 처리하며 AL을 가장 마지막에 둔다.
    reappeared.sort((a, b) {
      final aAl = a.deviceType.toUpperCase() == 'AL' ? 1 : 0;
      final bAl = b.deviceType.toUpperCase() == 'AL' ? 1 : 0;
      return aAl - bAl;
    });

    for (final mapping in reappeared) {
      final type = mapping.deviceType.toUpperCase();
      FlutterErrorLogger.logInfo(
        '[StandbyScreen] USB 재삽입 감지 ($type, ${mapping.vid}:${mapping.pid}) → 자동 재연결 시도',
      );

      if (type == 'AL') {
        final alcoUsb = _serviceLocator.alcoUsbService;
        if (!alcoUsb.isConnected) {
          await alcoUsb.tryConnectSavedDevice();
        }
      } else {
        // BP, HS, IN 등 MeasurementListener가 관리하는 기기
        if (!MeasurementListener().isPortInUse(type)) {
          await MeasurementListener().restartDevice(type);
        }
      }
    }
  }

  @override
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _initRetryTimer?.cancel();
    _videoReinitTimer?.cancel();
    routeObserver.unsubscribe(this);
    _controller.dispose();
    _waitContentActive.dispose();
    super.dispose();
  }

  void _startMemoryCleanupTimer() {
    _memoryCleanupTimer?.cancel();
    // 30분마다 이미지 캐시 정리 (하루종일 켜놓는 기기의 메모리 누적 방지)
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        PaintingBinding.instance.imageCache.maximumSize = 20;
        PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
      } catch (_) {}
    });

    _videoReinitTimer?.cancel();
    // 2시간마다 미디어 플레이어 완전 재초기화 (libmpv 네이티브 메모리 누적 방지)
    // WaitContentArea의 Key를 변경 → Flutter가 위젯을 dispose/재생성하여 Player 자원 해제
    _videoReinitTimer = Timer.periodic(const Duration(hours: 2), (_) {
      if (!mounted) return;
      setState(() => _videoPlayerKey++);
    });
  }

  Future<void> _handleTouchScreen() async {
    if (!mounted) return;

    // 스탠바이 화면 터치 시 항상 사용자 정보 초기화
    try {
      ref.read(userAuthProvider.notifier).clearUserAuth();
      ref.read(measureIdProvider.notifier).clearMeasureId();
      ref.read(guestModeProvider.notifier).clearGuestMode();
      ref.read(guestMeasureFlagProvider.notifier).clearGuestMeasureFlag();
      ref.read(guestSkipAuthProvider.notifier).clearSkipAuth();
      ref.read(lastBpResultProvider.notifier).clearResult();
      ref.read(sessionResultsProvider.notifier).clearResults();
      _serviceLocator.verifiedUserStorage.clearAll();
      _serviceLocator.guestPhoneStorage.clearPhoneNumber();
      print('[StandbyScreen] 사용자 정보 초기화 완료');
    } catch (e) {
      print('[StandbyScreen] 사용자 정보 초기화 실패: $e');
    }

    final kioskOption = await _serviceLocator.kioskOptionStorage.getOption();

    if (kioskOption != null && kioskOption.mode == 1) {
      final stepParts = kioskOption.step.split(';');
      if (stepParts.length >= 2 && stepParts[1].trim() == '2') {
        if (kioskOption.usecert == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AuthScreenWithBirthdayGender(),
            ),
          );
          return;
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GuestPhoneInputScreen(),
            ),
          );
          return;
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceSelectionScreen(),
          ),
        );
        return;
      }
    }

    // mode 2는 step과 관계없이 항상 AuthScreen으로 이동
    if (kioskOption != null && kioskOption.mode == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      return;
    }

    if (kioskOption != null && kioskOption.usecert == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreenWithBirthdayGender(),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _handleLanguageButton() {
    _isLanguageModalOpen = true;
    LanguageSelectionModal.show(context);
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  Future<void> _checkDeviceConnectionAndShowModal() async {
    if (!mounted || !_isKioskInitialized) return;

    final usbMappings = ref.read(deviceUsbMappingsProvider);
    final bluetoothMappings = ref.read(deviceBluetoothMappingsProvider);
    final devices = ref.read(deviceListProvider);

    int totalCount = 0;
    int disconnectedCount = 0;

    // 1. USB 기기별 연결 상태 확인 (break 없이 모두 확인)
    for (final mapping in usbMappings) {
      totalCount++;
      bool isConnected;

      if (mapping.deviceType.toUpperCase() == 'BP') {
        final device = devices.firstWhere(
          (d) => d.type == mapping.deviceType,
          orElse: () => Device(type: mapping.deviceType, name: ''),
        );
        final deviceName = device.name.toLowerCase();
        final isInBody =
            deviceName.contains('인바디') || deviceName.contains('inbody');
        final isCelvas =
            deviceName.contains('셀바스') || deviceName.contains('celvas');
        final isBp250 = deviceName.contains('bp250') ||
            deviceName.contains('bp210') ||
            deviceName.contains('accuniq') ||
            deviceName.contains('250');

        if (isInBody) {
          isConnected = await InBodyHealthCheck.checkConnection(
            mapping.deviceType,
            deviceName: device.name,
          );
        } else if (isCelvas) {
          isConnected = await CelvasHealthCheck.checkConnection(
            mapping.deviceType,
            deviceName: device.name,
            isBp250: isBp250,
          );
        } else {
          isConnected = await _serviceLocator.usbService.isDeviceConnected(
            mapping.deviceType,
          );
        }
      } else if (mapping.deviceType.toUpperCase() == 'AL') {
        final alcoUsb = _serviceLocator.alcoUsbService;
        if (alcoUsb.isConnectedReliable) {
          isConnected = true;
        } else if (alcoUsb.isPortOpen) {
          isConnected = false;
        } else {
          isConnected = await _serviceLocator.usbService.isDeviceConnected(
            mapping.deviceType,
          );
        }
      } else {
        isConnected = await _serviceLocator.usbService.isDeviceConnected(
          mapping.deviceType,
        );
      }

      if (!isConnected) disconnectedCount++;
    }

    // 2. Bluetooth 기기 연결 상태 확인
    for (final mapping in bluetoothMappings) {
      if (!mapping.isEnabled) continue;
      totalCount++;
      final bool isConnected;
      if (mapping.deviceType.toUpperCase() == 'AL') {
        isConnected = _serviceLocator.alcoBleService.isConnected;
      } else {
        isConnected = true;
      }
      if (!isConnected) disconnectedCount++;
    }

    // 모든 기기가 동시에 끊겼을 때만 모달 표시
    // 일부만 끊긴 경우(예: AL만 빠지고 BP는 연결됨)는 모달을 표시하지 않는다.
    final allDisconnected = totalCount > 0 && disconnectedCount == totalCount;

    // 모든 기기가 재연결되면 dismissed 상태를 해제 (다음 끊김 시 다시 표시되도록)
    if (!allDisconnected && _deviceConnectionModalDismissed) {
      _deviceConnectionModalDismissed = false;
    }

    // 사용자가 닫은(dismissed) 경우, 재진입/재연결 전까지는 다시 표시하지 않는다.
    final shouldShowModal = allDisconnected && !_deviceConnectionModalDismissed;

    print('[DeviceConnectionModal] total=$totalCount disconnected=$disconnectedCount');
    print(
        '[DeviceConnectionModal] Current modal visible: $_isDeviceConnectionModalVisible');

    if (_isDeviceConnectionModalVisible != shouldShowModal) {
      print(
          '[DeviceConnectionModal] Updating modal visibility to: $shouldShowModal');
      setState(() {
        _isDeviceConnectionModalVisible = shouldShowModal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // deviceConnectionStatusProvider가 5초마다 모든 기기 연결 상태를 갱신한다.
    // 별도 타이머 없이 watch만으로 모달 표시 여부를 자동 반영한다.
    final connectionStatus = ref.watch(deviceConnectionStatusProvider);
    final usbMappings = ref.watch(deviceUsbMappingsProvider);
    final bluetoothMappings = ref.watch(deviceBluetoothMappingsProvider);

    // USB 재삽입 자동 재연결:
    // usbDevicesProvider는 2초마다 현재 연결된 USB 기기 목록을 폴링한다.
    // 이전 주기에 없던 기기(새로 등장한 VID/PID)가 저장된 매핑과 일치하면
    // 서비스 레이어에 재연결을 트리거한다(포트는 VID/PID로 자동 탐색).
    ref.listen(usbDevicesProvider, (previous, current) {
      if (!_isKioskInitialized) return;
      final prevVidPids = _lastUsbVidPids;
      final currentVidPids =
          current.map((d) => '${d.vid}:${d.pid}').toSet();
      _lastUsbVidPids = currentVidPids;

      // 새로 등장한 기기만 처리 (없다가 생긴 것)
      final newlyAppeared = currentVidPids.difference(prevVidPids);
      if (newlyAppeared.isEmpty) return;

      _handleUsbDevicesReappeared(newlyAppeared, usbMappings);
    });

    // 연결 끊김 UI는 설정된 모든 기기가 동시에 끊겼을 때만 표시한다.
    // 일부 기기만 끊긴 경우(예: AL만 빠지고 BP는 연결됨)는 표시하지 않는다.
    bool hasAllDisconnected = false;
    if (_isKioskInitialized) {
      int totalCount = 0;
      int disconnectedCount = 0;

      for (final mapping in usbMappings) {
        totalCount++;
        if (connectionStatus[mapping.deviceType] != true) disconnectedCount++;
      }
      for (final mapping in bluetoothMappings) {
        if (!mapping.isEnabled) continue;
        totalCount++;
        if (connectionStatus[mapping.deviceType] != true) disconnectedCount++;
      }

      hasAllDisconnected = totalCount > 0 && disconnectedCount == totalCount;
    }

    // 사용자가 닫은(dismissed) 경우, 재진입/재연결 전까지는 다시 표시하지 않는다.
    // 모든 기기가 재연결되면 dismissed 해제 (다음 끊김 시 다시 표시되도록).
    final bool shouldShowModal = hasAllDisconnected && !_deviceConnectionModalDismissed;

    // setState 없이 build 결과만 갱신 (build 중 setState 호출 금지)
    if (!hasAllDisconnected && _deviceConnectionModalDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deviceConnectionModalDismissed = false;
      });
    }
    if (_isDeviceConnectionModalVisible != shouldShowModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isDeviceConnectionModalVisible != shouldShowModal) {
          setState(() => _isDeviceConnectionModalVisible = shouldShowModal);
        }
      });
    }

    return CommonLayout(
      onLogoTap: _refreshContent,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 헤더 높이를 우선 확보한 뒤 영상 크기를 결정한다.
            // 1) 최소 푸터 높이를 먼저 예약
            // 2) 남은 공간에서 비율을 유지하며 영상 높이 결정 (전체 너비 기준보다 클 경우 축소)
            // 3) 영상이 화면보다 클 경우 줄어들 수 있으나 비율은 유지된다.
            const videoAspectRatio = 1417.5 / 1080.0; // 영상 원본 비율 (높이/너비)
            const minFooterHeight = 100.0;             // 터치 아이콘·버튼을 위한 최소 푸터

            final maxVideoHeight = constraints.maxHeight - minFooterHeight;
            final videoByWidth  = constraints.maxWidth * videoAspectRatio;
            final videoHeight   = videoByWidth.clamp(0.0, maxVideoHeight);
            final footerHeight  = constraints.maxHeight - videoHeight;

            final iconSize = (footerHeight * 0.5).clamp(80.0, double.infinity);

            // 모달 높이 계산 (모달 위젯과 동일한 계산)
            final modalHeight = (footerHeight * 0.45).clamp(160.0, 240.0);

            // 모달이 푸터와 겹치도록 위치 설정 (모달의 일부가 푸터 안에 들어가도록)
            final modalOverlap = modalHeight * 0.85; // 모달 높이의 85% 정도가 푸터와 겹치도록

            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: videoHeight,
                      width: constraints.maxWidth,
                      child: WaitContentArea(
                        key: ValueKey(_videoPlayerKey),
                        onTap: _handleTouchScreen,
                        isActiveNotifier: _waitContentActive,
                      ),
                    ),
                    Container(
                      height: footerHeight,
                      color: Color(0xFF3C3C3C),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _handleTouchScreen,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _scaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: SvgPicture.asset(
                                        'assets/icons/touch.svg',
                                        width: iconSize,
                                        height: iconSize,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: _getResponsiveSize(context, 24),
                            top: 0,
                            bottom: 0,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTapDown: (_) {
                                  setState(() {
                                    _isLanguageButtonPressed = true;
                                  });
                                },
                                onTapUp: (_) {
                                  setState(() {
                                    _isLanguageButtonPressed = false;
                                  });
                                  _handleLanguageButton();
                                },
                                onTapCancel: () {
                                  setState(() {
                                    _isLanguageButtonPressed = false;
                                  });
                                },
                                child: Container(
                                  width: _getResponsiveSize(context, 148),
                                  height: _getResponsiveSize(context, 148),
                                  decoration: BoxDecoration(
                                    color: _isLanguageButtonPressed
                                        ? Color(0xFF227EFF)
                                        : Color(0xFF363E4B),
                                    borderRadius: BorderRadius.circular(
                                      _getResponsiveSize(context, 16),
                                    ),
                                    border: Border.all(
                                      color: Color(0xFF505663),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/language.svg',
                                        width: _getResponsiveSize(context, 56),
                                        height: _getResponsiveSize(context, 56),
                                      ),
                                      SizedBox(
                                          height: _getResponsiveSize(context, 12)),
                                      Text(
                                        l10n.languageButton,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.bodyFontFamily,
                                          fontSize: _getResponsiveSize(context, 24),
                                          fontVariations: <FontVariation>[
                                            FontVariation('wght', 600),
                                          ],
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 연결 상태 모달 - 푸터와 겹쳐서 표시 (모달의 일부가 푸터 안에 들어감)
                if (_isDeviceConnectionModalVisible)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() {
                          _isDeviceConnectionModalVisible = false;
                          _deviceConnectionModalDismissed = true;
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: footerHeight - modalOverlap,
                              left: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {},
                                behavior: HitTestBehavior.opaque,
                                child: DeviceConnectionModal(
                                  footerHeight: footerHeight,
                                ),
                              ),
                            ),
                          ],
                ),
              ),
            ),
          ),
              ],
            );
          },
        ),
      ),
    );
  }
}
