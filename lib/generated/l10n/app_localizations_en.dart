// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Template';

  @override
  String get headerTitle => 'Smart Health Care';

  @override
  String get touchScreenMessage => 'Please touch the screen!';

  @override
  String get authTitle =>
      'Please enter your <b>user number</b> or <b>mobile phone number</b>\nor scan your <b>user barcode</b> or <b>QR code</b>.';

  @override
  String get authInputHint => 'Enter user number or phone number';

  @override
  String get authClearAll => 'Clear All';

  @override
  String get authConfirm => 'Confirm';

  @override
  String get loadingDefault => 'Processing...';

  @override
  String get systemErrorTitle => 'System Error';

  @override
  String get systemErrorMessage =>
      'A system error has occurred.\nPlease contact the administrator.';

  @override
  String get contactAdministrator => 'Please contact the administrator.';

  @override
  String get confirm => 'Confirm';

  @override
  String get progressTitle => 'In Progress.';

  @override
  String get progressMessage => 'Please wait a moment.';

  @override
  String get invalidPhoneFormatTitle => 'Input Error';

  @override
  String get invalidPhoneFormat =>
      'Invalid phone number format.\nPlease enter 11 digits.';

  @override
  String get noMemberFound => 'No matching member information found.';

  @override
  String registerQuestion(String highlight) {
    return 'Would you like to $highlight with this number?';
  }

  @override
  String get registerHighlight => 'register';

  @override
  String get registerPrefix => 'Would you like to';

  @override
  String get registerSuffix => 'with this number?';

  @override
  String get measurementHighlight => 'measure';

  @override
  String get measurementQuestion => 'Would you like to measure?';

  @override
  String get phoneCheckMessage => 'Please check your phone number.';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get registrationCompleteTitle => 'Registration link has been sent.';

  @override
  String get registrationCompleteMessage =>
      'Please <c>register</c> on your mobile phone\nand proceed with the measurement.';

  @override
  String get userConfirmQuestion => 'Is this you?';

  @override
  String get userConfirmYes => 'Yes, that\'s correct';

  @override
  String get userConfirmNo => 'No';

  @override
  String get adminPasswordTitle => 'Admin Password';

  @override
  String get adminPasswordErrorTitle => 'Error';

  @override
  String get adminPasswordErrorMessage => 'The admin password is incorrect.';

  @override
  String get adminSettingsTitle => 'Admin Settings';

  @override
  String get adminPasswordChangeTitle => 'Change Admin Password';

  @override
  String get adminCurrentPasswordLabel => 'Current Password';

  @override
  String get adminNewPasswordLabel => 'New Password';

  @override
  String get adminConfirmPasswordLabel => 'Confirm New Password';

  @override
  String get adminPasswordChangeButton => 'Change Password';

  @override
  String get adminPasswordChanging => 'Changing...';

  @override
  String get adminPasswordAllFieldsRequired =>
      'Please enter all passwords as 4 digits.';

  @override
  String get adminPasswordMismatch => 'New passwords do not match.';

  @override
  String get adminPasswordCurrentIncorrect => 'Current password is incorrect.';

  @override
  String get adminPasswordChangeSuccess => 'Password has been changed.';

  @override
  String get adminPasswordChangeError =>
      'An error occurred while changing the password.';

  @override
  String get cancel => 'Cancel';

  @override
  String get adminLanguageSelectionTitle => 'Language Settings';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get deviceTypeBP => 'Blood Pressure';

  @override
  String get deviceTypeHS => 'Height & Weight';

  @override
  String get deviceTypeVA => 'Visual Acuity';

  @override
  String get deviceTypeCM => 'Color Vision';

  @override
  String get deviceTypeBC => 'Body Composition';

  @override
  String get deviceTypeBS => 'Blood Sugar';

  @override
  String get deviceTypeHRV => 'ANS (Non-contact)';

  @override
  String get deviceTypeST => 'ANS (Contact)';

  @override
  String get deviceTypeAL => 'Alcohol';

  @override
  String get deviceTypeHC => 'Height & Weight Scale';

  @override
  String get deviceTypeMF => 'Mediform';

  @override
  String get deviceTypeLU => 'Lung Capacity';

  @override
  String get deviceTypeOM => 'Other';

  @override
  String get deviceSelectionTitle => 'Available Devices';

  @override
  String get noDevicesAvailable => 'No devices available';

  @override
  String get bloodPressureSample => 'BP Sample';

  @override
  String get bloodPressureResultTitle => 'Blood Pressure Result';

  @override
  String get systolicPressure => 'Systolic Pressure';

  @override
  String get diastolicPressure => 'Diastolic Pressure';

  @override
  String get pulse => 'Pulse';

  @override
  String get mmHg => 'mmHg';

  @override
  String get bpm => 'bpm';

  @override
  String get resultHidden => 'Hide Result';

  @override
  String get resultHiddenMessage => 'Result is hidden';

  @override
  String get videoArea => 'Video Area';

  @override
  String get remeasure => 'Remeasure';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get sendMessagePending =>
      'Message sending feature is under preparation.';

  @override
  String get bpStatusNormal => 'Normal';

  @override
  String get bpStatusCaution => 'Caution';

  @override
  String get bpStatusPreHypertension => 'Prehypertension';

  @override
  String get bpStatusHypertension1 => 'Hypertension Stage 1';

  @override
  String get bpStatusHypertension2 => 'Hypertension Stage 2';

  @override
  String get bpStatusHypertension3 => 'Hypertension Stage 3';

  @override
  String get heightWeightResultTitle => 'Height & Weight Result';

  @override
  String get bmiStatusUnderweight => 'Underweight';

  @override
  String get bmiStatusNormal => 'Normal';

  @override
  String get bmiStatusPreObese => 'Pre-obese';

  @override
  String get bmiStatusObese1 => 'Obesity I';

  @override
  String get bmiStatusObese2 => 'Obesity II';

  @override
  String get bmiStatusObese3 => 'Obesity III';

  @override
  String get resultShow => 'Show Result';

  @override
  String get resultHiddenGuide =>
      'You can receive measurement results via text message.';

  @override
  String get sendMessageSuccess => 'Measurement results have been sent.';

  @override
  String get sendMessageSuccessHighlight => 'Measurement results';

  @override
  String get sendMessageSuccessSuffix => ' have been sent.';

  @override
  String get languageSelection => 'Language Selection';

  @override
  String get languageButton => 'Language';

  @override
  String get helpButton => 'Help Guide';

  @override
  String get languageKoreanNative => '한국어';

  @override
  String get languageKoreanEng => 'korean';

  @override
  String get languageEnglishNative => 'English';

  @override
  String get languageEnglishEng => 'English';

  @override
  String get guestPhoneInputTitle =>
      'Please enter your phone number.\nMeasurement results will be sent to your phone.';

  @override
  String get guestPhoneInputTitleHighlight1 => 'phone number';

  @override
  String get guestPhoneInputTitleHighlight2 => 'Measurement results';

  @override
  String get agreeAllAndSend => 'Agree All and Send';

  @override
  String get termsAgreement => '*Terms Agreement';

  @override
  String get privacyPolicy => 'Privacy Policy (Required)';

  @override
  String get termsOfService => 'Terms of Service (Required)';

  @override
  String get thirdPartyInfo => 'Third Party Information (Required)';

  @override
  String get sensitiveInfo => 'Sensitive Information (Required)';

  @override
  String get viewDetails => 'View';

  @override
  String get agreementContentUnavailable =>
      'Could not load the agreement content. Please try again later.';

  @override
  String get bloodPressure => 'Blood Pressure';

  @override
  String get systolicBloodPressure => 'Systolic Blood Pressure';

  @override
  String get diastolicBloodPressure => 'Diastolic Blood Pressure';

  @override
  String get measurementResult => 'Measurement Result';

  @override
  String get requestAuth => 'Request Auth';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterVerificationCode => 'Please enter verification code.';

  @override
  String get enterPhoneNumberCorrectly =>
      'Please enter phone number correctly.';

  @override
  String get enterBirthday => 'Please enter birthday.';

  @override
  String get enterVerificationCode6Digits =>
      'Please enter 6-digit verification code.';

  @override
  String get enterVerificationCode4Digits =>
      'Please enter 4-digit verification code.';

  @override
  String get requestVerificationCodeFirst =>
      'Please request verification code first.';

  @override
  String get verificationFailed => 'Verification Failed';

  @override
  String get verificationCodeMismatch => 'Verification code does not match.';

  @override
  String get authRequired => 'Authentication Required';

  @override
  String get requestAuthFirst => 'Please request authentication first.';

  @override
  String get error => 'Error';

  @override
  String get authInfoNotFound => 'Authentication information not found.';

  @override
  String get measurementInfoNotFound => 'Measurement information not found.';

  @override
  String get enterCorrectPhoneNumber => 'Please enter correct phone number.';

  @override
  String get enterCorrectBirthday => 'Please enter correct birthday.';

  @override
  String get measurementResultNotFound => 'Measurement result not found.';

  @override
  String get defaultKioskPlace => 'Meditech Kiosk';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get homeScreen => 'Home Screen';

  @override
  String get measurementGuide => 'Measurement Guide';

  @override
  String get bloodPressureMeasurementGuide =>
      'Blood Pressure Measurement Guide';

  @override
  String get birthday => 'Birthday';

  @override
  String get gender => 'Gender';

  @override
  String get pleaseEnter => 'Please enter';

  @override
  String get willBeSentToPhone => 'will be sent to your phone.';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get guestAuthRequiredTitle => 'Measurement completed.';

  @override
  String guestAuthRequiredMessage(String highlight) {
    return 'Please enter $highlight to check the results.';
  }

  @override
  String get guestAuthRequiredHighlight => 'user information';

  @override
  String get bluetoothDeviceManagement => 'Bluetooth Device Management';

  @override
  String get bluetoothPairingGuide => 'Bluetooth Pairing Guide';

  @override
  String get scanningDevices => 'Searching for devices';

  @override
  String get deviceFound => 'Device Found';

  @override
  String get pairingRequired => 'Pairing required';

  @override
  String get bluetoothNotEnabled => 'Bluetooth is not enabled';

  @override
  String get permissionRequired => 'Bluetooth permission required';

  @override
  String get connectDevice => 'Connect';

  @override
  String get disconnectDevice => 'Disconnect';

  @override
  String get registerDevice => 'Register';

  @override
  String get deleteDevice => 'Delete';

  @override
  String get deviceConnectionSuccess => 'Connection successful';

  @override
  String get deviceConnectionFailed => 'Connection failed';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get rescan => 'Rescan';

  @override
  String get deviceConnectionNotConfirmed => 'Device connection not confirmed';

  @override
  String get deviceConnectionCheckMessage =>
      'Please check the device and port.';

  @override
  String get alcoResultTitle => 'Alcohol Test Result';

  @override
  String get alcoResultLoading => 'Receiving result data...';

  @override
  String get alcoResultHidden => 'Result is hidden.';

  @override
  String get alcoResultPass => 'Measurement result is normal.';

  @override
  String get alcoResultPassSub => '(When blood alcohol level is below 0.030%)';

  @override
  String get alcoResultFailGuide =>
      'Please follow the administrator\'s guidance.';

  @override
  String get alcoResultFailSub =>
      '(When blood alcohol level is 0.030% or above)';

  @override
  String get hwHeightLabel => 'Height';

  @override
  String get hwWeightLabel => 'Weight';

  @override
  String get hwBmiLabel => 'BMI';
}
