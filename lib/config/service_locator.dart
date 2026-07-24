import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_template/data/network/api_service.dart';
import 'package:flutter_template/core/utils/token_storage_service.dart';
import 'package:flutter_template/core/utils/kiosk_option_storage.dart';
import 'package:flutter_template/data/repository/auth_repository.dart';
import 'package:flutter_template/data/local/admin_password_service.dart';
import 'package:flutter_template/data/local/locale_service.dart';
import 'package:flutter_template/data/local/rich_text_storage_service.dart';
import 'package:flutter_template/data/local/device_usb_mapping_storage.dart';
import 'package:flutter_template/data/local/guest_phone_storage.dart';
import 'package:flutter_template/data/local/verified_user_storage.dart';
import 'package:flutter_template/data/local/device_bluetooth_mapping_storage.dart';
import 'package:flutter_template/data/local/content_storage_service.dart';
import 'package:flutter_template/data/local/kiosk_id_storage.dart';
import 'package:flutter_template/data/local/debug_mode_service.dart';
import 'package:flutter_template/data/local/app_start_delay_service.dart';
import 'package:flutter_template/data/local/app_lock_service.dart';
import 'package:flutter_template/data/local/reboot_schedule_service.dart';
import 'package:flutter_template/data/local/shutdown_schedule_service.dart';
import 'package:flutter_template/data/repository/usb_repository.dart';
import 'package:flutter_template/core/utils/usb_service.dart';
import 'package:flutter_template/core/utils/bluetooth_service.dart';
import 'package:flutter_template/core/utils/alco_ble_service.dart';
import 'package:flutter_template/core/utils/alco_usb_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final TokenStorageService _tokenStorage;
  late final KioskOptionStorage _kioskOptionStorage;
  late final ApiService _apiService;
  late final AuthRepository _authRepository;
  late final AdminPasswordService _adminPasswordService;
  late final LocaleService _localeService;
  late final RichTextStorageService _richTextStorageService;
  late final DeviceUsbMappingStorage _deviceUsbMappingStorage;
  late final GuestPhoneStorage _guestPhoneStorage;
  late final VerifiedUserStorage _verifiedUserStorage;
  late final DeviceBluetoothMappingStorage _deviceBluetoothMappingStorage;
  late final UsbRepository _usbRepository;
  late final UsbService _usbService;
  late final BleService _bleService;
  late final AlcoBleService _alcoBleService;
  late final AlcoUsbService _alcoUsbService;
  late final ContentStorageService _contentStorageService;
  late final KioskIdStorage _kioskIdStorage;
  late final DebugModeService _debugModeService;
  late final AppStartDelayService _appStartDelayService;
  late final AppLockService _appLockService;
  late final RebootScheduleService _rebootScheduleService;
  late final ShutdownScheduleService _shutdownScheduleService;
  late final SharedPreferences _sharedPreferences;

  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _tokenStorage = TokenStorageService(_sharedPreferences);
    _kioskOptionStorage = KioskOptionStorage(_sharedPreferences);
    _apiService = ApiService.create(tokenStorage: _tokenStorage);
    _authRepository = AuthRepository(_apiService);
    _adminPasswordService = AdminPasswordService(_sharedPreferences);
    _localeService = LocaleService(_sharedPreferences);
    _richTextStorageService = RichTextStorageService(_sharedPreferences);
    _deviceUsbMappingStorage = DeviceUsbMappingStorage(_sharedPreferences);
    _guestPhoneStorage = GuestPhoneStorage(_sharedPreferences);
    _verifiedUserStorage = VerifiedUserStorage(_sharedPreferences);
    _deviceBluetoothMappingStorage = DeviceBluetoothMappingStorage(_sharedPreferences);
    _contentStorageService = ContentStorageService(_sharedPreferences);
    _kioskIdStorage = KioskIdStorage(_sharedPreferences);
    _debugModeService = DebugModeService(_sharedPreferences);
    _appStartDelayService = AppStartDelayService(_sharedPreferences);
    _appLockService = AppLockService(_sharedPreferences);
    _rebootScheduleService = RebootScheduleService(_sharedPreferences);
    _shutdownScheduleService = ShutdownScheduleService(_sharedPreferences);
    _usbRepository = UsbRepository();
    _usbService = UsbService(_usbRepository, _deviceUsbMappingStorage);
    _bleService = BleService();
    _alcoBleService = AlcoBleService();
    _alcoUsbService = AlcoUsbService(_deviceUsbMappingStorage);
  }

  TokenStorageService get tokenStorage => _tokenStorage;
  KioskOptionStorage get kioskOptionStorage => _kioskOptionStorage;
  ApiService get apiService => _apiService;
  AuthRepository get authRepository => _authRepository;
  AdminPasswordService get adminPasswordService => _adminPasswordService;
  LocaleService get localeService => _localeService;
  RichTextStorageService get richTextStorageService => _richTextStorageService;
  DeviceUsbMappingStorage get deviceUsbMappingStorage =>
      _deviceUsbMappingStorage;
  GuestPhoneStorage get guestPhoneStorage => _guestPhoneStorage;
  VerifiedUserStorage get verifiedUserStorage => _verifiedUserStorage;
  DeviceBluetoothMappingStorage get deviceBluetoothMappingStorage =>
      _deviceBluetoothMappingStorage;
  ContentStorageService get contentStorageService => _contentStorageService;
  KioskIdStorage get kioskIdStorage => _kioskIdStorage;
  DebugModeService get debugModeService => _debugModeService;
  AppStartDelayService get appStartDelayService => _appStartDelayService;
  AppLockService get appLockService => _appLockService;
  RebootScheduleService get rebootScheduleService => _rebootScheduleService;
  ShutdownScheduleService get shutdownScheduleService => _shutdownScheduleService;
  UsbService get usbService => _usbService;
  BleService get bleService => _bleService;
  AlcoBleService get alcoBleService => _alcoBleService;
  AlcoUsbService get alcoUsbService => _alcoUsbService;
}
