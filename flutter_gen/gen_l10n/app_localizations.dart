import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Flutter Template'**
  String get appTitle;

  /// The title displayed in the header
  ///
  /// In en, this message translates to:
  /// **'Smart Health Care'**
  String get headerTitle;

  /// Message to prompt user to touch the screen
  ///
  /// In en, this message translates to:
  /// **'Please touch the screen!'**
  String get touchScreenMessage;

  /// Authentication screen title
  ///
  /// In en, this message translates to:
  /// **'Please enter your <b>user number</b> or <b>mobile phone number</b>\nor scan your <b>user barcode</b> or <b>QR code</b>.'**
  String get authTitle;

  /// Authentication input field hint
  ///
  /// In en, this message translates to:
  /// **'User number or mobile phone number'**
  String get authInputHint;

  /// Clear all button text
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get authClearAll;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get authConfirm;

  /// Default loading message
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get loadingDefault;

  /// System error title
  ///
  /// In en, this message translates to:
  /// **'System Error'**
  String get systemErrorTitle;

  /// System error message
  ///
  /// In en, this message translates to:
  /// **'A system error has occurred.\nPlease contact the administrator.'**
  String get systemErrorMessage;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Progress title
  ///
  /// In en, this message translates to:
  /// **'In Progress.'**
  String get progressTitle;

  /// Progress message
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get progressMessage;

  /// Invalid phone number format title
  ///
  /// In en, this message translates to:
  /// **'Input Error'**
  String get invalidPhoneFormatTitle;

  /// Invalid phone number format message
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format.\nPlease enter 11 digits.'**
  String get invalidPhoneFormat;

  /// No member information found
  ///
  /// In en, this message translates to:
  /// **'No matching member information found.'**
  String get noMemberFound;

  /// Registration confirmation question
  ///
  /// In en, this message translates to:
  /// **'Would you like to {highlight} with this number?'**
  String registerQuestion(String highlight);

  /// Registration highlight text
  ///
  /// In en, this message translates to:
  /// **'register'**
  String get registerHighlight;

  /// Registration question prefix
  ///
  /// In en, this message translates to:
  /// **'Would you like to'**
  String get registerPrefix;

  /// Registration question suffix
  ///
  /// In en, this message translates to:
  /// **'with this number?'**
  String get registerSuffix;

  /// Phone number check message
  ///
  /// In en, this message translates to:
  /// **'Please check your phone number.'**
  String get phoneCheckMessage;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Registration complete title
  ///
  /// In en, this message translates to:
  /// **'Registration link has been sent.'**
  String get registrationCompleteTitle;

  /// Registration complete message
  ///
  /// In en, this message translates to:
  /// **'Please <c>register</c> on your mobile phone\nand proceed with the measurement.'**
  String get registrationCompleteMessage;

  /// User confirmation question
  ///
  /// In en, this message translates to:
  /// **'Is this you?'**
  String get userConfirmQuestion;

  /// Yes, that's correct button
  ///
  /// In en, this message translates to:
  /// **'Yes, that\'s correct'**
  String get userConfirmYes;

  /// No button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get userConfirmNo;

  /// Admin password dialog title
  ///
  /// In en, this message translates to:
  /// **'Admin Password'**
  String get adminPasswordTitle;

  /// Admin password error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get adminPasswordErrorTitle;

  /// Admin password error message
  ///
  /// In en, this message translates to:
  /// **'The admin password is incorrect.'**
  String get adminPasswordErrorMessage;

  /// Admin settings screen title
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettingsTitle;

  /// Admin password change title
  ///
  /// In en, this message translates to:
  /// **'Change Admin Password'**
  String get adminPasswordChangeTitle;

  /// Current password label
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get adminCurrentPasswordLabel;

  /// New password label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get adminNewPasswordLabel;

  /// Confirm new password label
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get adminConfirmPasswordLabel;

  /// Change password button
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get adminPasswordChangeButton;

  /// Changing password status
  ///
  /// In en, this message translates to:
  /// **'Changing...'**
  String get adminPasswordChanging;

  /// All password fields must be 4 digits
  ///
  /// In en, this message translates to:
  /// **'Please enter all passwords as 4 digits.'**
  String get adminPasswordAllFieldsRequired;

  /// New passwords do not match
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get adminPasswordMismatch;

  /// Current password is incorrect
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get adminPasswordCurrentIncorrect;

  /// Password changed successfully
  ///
  /// In en, this message translates to:
  /// **'Password has been changed.'**
  String get adminPasswordChangeSuccess;

  /// Error occurred while changing password
  ///
  /// In en, this message translates to:
  /// **'An error occurred while changing the password.'**
  String get adminPasswordChangeError;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Language selection title
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get adminLanguageSelectionTitle;

  /// Korean language
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Blood Pressure device type
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get deviceTypeBP;

  /// Height Scale device type
  ///
  /// In en, this message translates to:
  /// **'Height & Weight'**
  String get deviceTypeHS;

  /// Visual Acuity device type
  ///
  /// In en, this message translates to:
  /// **'Visual Acuity'**
  String get deviceTypeVA;

  /// Colorimetric device type
  ///
  /// In en, this message translates to:
  /// **'Color Vision'**
  String get deviceTypeCM;

  /// Body Composition device type
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get deviceTypeBC;

  /// Blood Sugar device type
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar'**
  String get deviceTypeBS;

  /// Heart Rate Variability device type
  ///
  /// In en, this message translates to:
  /// **'ANS (Non-contact)'**
  String get deviceTypeHRV;

  /// Stress Test device type
  ///
  /// In en, this message translates to:
  /// **'ANS (Contact)'**
  String get deviceTypeST;

  /// Alcohol device type
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get deviceTypeAL;

  /// Mediform device type
  ///
  /// In en, this message translates to:
  /// **'Mediform'**
  String get deviceTypeMF;

  /// Lung capacity device type
  ///
  /// In en, this message translates to:
  /// **'Lung Capacity'**
  String get deviceTypeLU;

  /// Other measuring device type
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get deviceTypeOM;

  /// Device selection screen title
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get deviceSelectionTitle;

  /// No devices available message
  ///
  /// In en, this message translates to:
  /// **'No devices available'**
  String get noDevicesAvailable;

  /// Blood pressure sample button
  ///
  /// In en, this message translates to:
  /// **'BP Sample'**
  String get bloodPressureSample;

  /// Blood pressure result screen title
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Result'**
  String get bloodPressureResultTitle;

  /// Systolic blood pressure
  ///
  /// In en, this message translates to:
  /// **'Systolic Pressure'**
  String get systolicPressure;

  /// Diastolic blood pressure
  ///
  /// In en, this message translates to:
  /// **'Diastolic Pressure'**
  String get diastolicPressure;

  /// Pulse
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get pulse;

  /// Unit for blood pressure
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get mmHg;

  /// Unit for pulse (beats per minute)
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpm;

  /// Hide result button
  ///
  /// In en, this message translates to:
  /// **'Hide Result'**
  String get resultHidden;

  /// Message when result is hidden
  ///
  /// In en, this message translates to:
  /// **'Result is hidden'**
  String get resultHiddenMessage;

  /// Video area placeholder
  ///
  /// In en, this message translates to:
  /// **'Video Area'**
  String get videoArea;

  /// Remeasure button
  ///
  /// In en, this message translates to:
  /// **'Remeasure'**
  String get remeasure;

  /// Send message button
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// Message sending feature under preparation
  ///
  /// In en, this message translates to:
  /// **'Message sending feature is under preparation.'**
  String get sendMessagePending;

  /// Normal blood pressure status
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bpStatusNormal;

  /// Caution blood pressure status
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get bpStatusCaution;

  /// Prehypertension status
  ///
  /// In en, this message translates to:
  /// **'Prehypertension'**
  String get bpStatusPreHypertension;

  /// Hypertension stage 1 status
  ///
  /// In en, this message translates to:
  /// **'Hypertension Stage 1'**
  String get bpStatusHypertension1;

  /// Hypertension stage 2 status
  ///
  /// In en, this message translates to:
  /// **'Hypertension Stage 2'**
  String get bpStatusHypertension2;

  /// Hypertension stage 3 status
  ///
  /// In en, this message translates to:
  /// **'Hypertension Stage 3'**
  String get bpStatusHypertension3;

  /// Show result button
  ///
  /// In en, this message translates to:
  /// **'Show Result'**
  String get resultShow;

  /// Guide message when result is hidden
  ///
  /// In en, this message translates to:
  /// **'You can receive measurement results via text message.'**
  String get resultHiddenGuide;

  /// Message sent successfully
  ///
  /// In en, this message translates to:
  /// **'Measurement results have been sent.'**
  String get sendMessageSuccess;

  /// Highlighted text for message sent
  ///
  /// In en, this message translates to:
  /// **'Measurement results'**
  String get sendMessageSuccessHighlight;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageSelection;

  /// Language button label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageButton;

  /// Help button label
  ///
  /// In en, this message translates to:
  /// **'Help Guide'**
  String get helpButton;

  /// Korean in Korean
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKoreanNative;

  /// Korean in English
  ///
  /// In en, this message translates to:
  /// **'korean'**
  String get languageKoreanEng;

  /// English in English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishNative;

  /// English in English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishEng;

  /// Guest phone input screen title
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.\nMeasurement results will be sent to your phone.'**
  String get guestPhoneInputTitle;

  /// Highlighted text 1
  ///
  /// In en, this message translates to:
  /// **'phone number'**
  String get guestPhoneInputTitleHighlight1;

  /// Highlighted text 2
  ///
  /// In en, this message translates to:
  /// **'Measurement results'**
  String get guestPhoneInputTitleHighlight2;

  /// Agree all and send button
  ///
  /// In en, this message translates to:
  /// **'Agree All and Send'**
  String get agreeAllAndSend;

  /// Terms agreement section title
  ///
  /// In en, this message translates to:
  /// **'*Terms Agreement'**
  String get termsAgreement;

  /// Privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy (Required)'**
  String get privacyPolicy;

  /// Terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service (Required)'**
  String get termsOfService;

  /// Third party information
  ///
  /// In en, this message translates to:
  /// **'Third Party Information (Required)'**
  String get thirdPartyInfo;

  /// View details button
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewDetails;

  /// Blood pressure
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// Systolic blood pressure
  ///
  /// In en, this message translates to:
  /// **'Systolic Blood Pressure'**
  String get systolicBloodPressure;

  /// Diastolic blood pressure
  ///
  /// In en, this message translates to:
  /// **'Diastolic Blood Pressure'**
  String get diastolicBloodPressure;

  /// Measurement result
  ///
  /// In en, this message translates to:
  /// **'Measurement Result'**
  String get measurementResult;

  /// Request authentication button
  ///
  /// In en, this message translates to:
  /// **'Request Auth'**
  String get requestAuth;

  /// Verification code
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// Enter verification code hint
  ///
  /// In en, this message translates to:
  /// **'Please enter verification code.'**
  String get enterVerificationCode;

  /// Enter phone number correctly message
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number correctly.'**
  String get enterPhoneNumberCorrectly;

  /// Enter birthday message
  ///
  /// In en, this message translates to:
  /// **'Please enter birthday.'**
  String get enterBirthday;

  /// Enter 6-digit verification code message
  ///
  /// In en, this message translates to:
  /// **'Please enter 6-digit verification code.'**
  String get enterVerificationCode6Digits;

  /// Enter 4-digit verification code message
  ///
  /// In en, this message translates to:
  /// **'Please enter 4-digit verification code.'**
  String get enterVerificationCode4Digits;

  /// Request verification code first message
  ///
  /// In en, this message translates to:
  /// **'Please request verification code first.'**
  String get requestVerificationCodeFirst;

  /// Verification failed title
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// Verification code mismatch message
  ///
  /// In en, this message translates to:
  /// **'Verification code does not match.'**
  String get verificationCodeMismatch;

  /// Authentication required title
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authRequired;

  /// Request authentication first message
  ///
  /// In en, this message translates to:
  /// **'Please request authentication first.'**
  String get requestAuthFirst;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Authentication info not found message
  ///
  /// In en, this message translates to:
  /// **'Authentication information not found.'**
  String get authInfoNotFound;

  /// Measurement info not found message
  ///
  /// In en, this message translates to:
  /// **'Measurement information not found.'**
  String get measurementInfoNotFound;

  /// Enter correct phone number message
  ///
  /// In en, this message translates to:
  /// **'Please enter correct phone number.'**
  String get enterCorrectPhoneNumber;

  /// Enter correct birthday message
  ///
  /// In en, this message translates to:
  /// **'Please enter correct birthday.'**
  String get enterCorrectBirthday;

  /// Measurement result not found message
  ///
  /// In en, this message translates to:
  /// **'Measurement result not found.'**
  String get measurementResultNotFound;

  /// Default kiosk place name
  ///
  /// In en, this message translates to:
  /// **'Meditech Kiosk'**
  String get defaultKioskPlace;

  /// Male gender
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Female gender
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Home screen button
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get homeScreen;

  /// Measurement guide
  ///
  /// In en, this message translates to:
  /// **'Measurement Guide'**
  String get measurementGuide;

  /// Blood pressure measurement guide
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Measurement Guide'**
  String get bloodPressureMeasurementGuide;

  /// Birthday label
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// Gender label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Please enter suffix
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get pleaseEnter;

  /// Will be sent to phone message
  ///
  /// In en, this message translates to:
  /// **'will be sent to your phone.'**
  String get willBeSentToPhone;

  /// AM period
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// PM period
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// Guest authentication required title
  ///
  /// In en, this message translates to:
  /// **'Measurement completed.'**
  String get guestAuthRequiredTitle;

  /// Guest authentication required message
  ///
  /// In en, this message translates to:
  /// **'Please enter {highlight} to check the results.'**
  String guestAuthRequiredMessage(String highlight);

  /// Guest authentication required highlight text
  ///
  /// In en, this message translates to:
  /// **'user information'**
  String get guestAuthRequiredHighlight;

  /// Bluetooth device management title
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Device Management'**
  String get bluetoothDeviceManagement;

  /// Bluetooth pairing guide title
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Pairing Guide'**
  String get bluetoothPairingGuide;

  /// Scanning devices message
  ///
  /// In en, this message translates to:
  /// **'Searching for devices'**
  String get scanningDevices;

  /// Device found message
  ///
  /// In en, this message translates to:
  /// **'Device Found'**
  String get deviceFound;

  /// Pairing required message
  ///
  /// In en, this message translates to:
  /// **'Pairing required'**
  String get pairingRequired;

  /// Bluetooth not enabled message
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is not enabled'**
  String get bluetoothNotEnabled;

  /// Bluetooth permission required message
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission required'**
  String get permissionRequired;

  /// Connect device button
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectDevice;

  /// Disconnect device button
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectDevice;

  /// Register device button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerDevice;

  /// Delete device button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDevice;

  /// Device connection success message
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get deviceConnectionSuccess;

  /// Device connection failed message
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get deviceConnectionFailed;

  /// No devices found message
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// Rescan button
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
