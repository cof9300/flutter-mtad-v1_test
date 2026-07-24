// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '플러터 템플릿';

  @override
  String get headerTitle => '스마트 건강관리';

  @override
  String get touchScreenMessage => '화면을 터치해주세요!';

  @override
  String get authTitle =>
      '<b>사용자 번호</b> 또는 <b>휴대폰 번호</b>를 입력해주시거나\n<b>사용자 바코드</b> 또는 <b>QR 코드</b>를 리더기에 대주세요.';

  @override
  String get authInputHint => '휴대폰 번호';

  @override
  String get authClearAll => '전체삭제';

  @override
  String get authConfirm => '확인';

  @override
  String get loadingDefault => '처리 중입니다...';

  @override
  String get systemErrorTitle => '시스템 오류';

  @override
  String get systemErrorMessage => '시스템에 오류가 발생했습니다.\n관리자에게 문의해주세요.';

  @override
  String get confirm => '확인';

  @override
  String get progressTitle => '진행중입니다.';

  @override
  String get progressMessage => '잠시만 기다려주세요.';

  @override
  String get invalidPhoneFormatTitle => '입력 오류';

  @override
  String get invalidPhoneFormat => '전화번호 형식이 알맞지 않습니다.\n11자리 숫자를 입력해주세요.';

  @override
  String get noMemberFound => '일치하는 회원 정보가 없습니다.';

  @override
  String registerQuestion(String highlight) {
    return '이 번호로 $highlight 하시겠습니까?';
  }

  @override
  String get registerHighlight => '회원가입';

  @override
  String get registerPrefix => '이 번호로';

  @override
  String get registerSuffix => '하시겠습니까?';

  @override
  String get phoneCheckMessage => '휴대폰 번호를 확인해주세요.';

  @override
  String get no => '아니요';

  @override
  String get yes => '예';

  @override
  String get registrationCompleteTitle => '회원가입 링크가 전송되었습니다.';

  @override
  String get registrationCompleteMessage => '휴대폰에서 <c>회원가입</c> 후\n측정을 진행 해주세요.';

  @override
  String get userConfirmQuestion => '본인이 맞으십니까?';

  @override
  String get userConfirmYes => '네, 맞습니다';

  @override
  String get userConfirmNo => '아닙니다';

  @override
  String get adminPasswordTitle => '관리자 비밀번호';

  @override
  String get adminPasswordErrorTitle => '오류';

  @override
  String get adminPasswordErrorMessage => '관리자 비밀번호가 잘못되었습니다.';

  @override
  String get adminSettingsTitle => '관리자 환경설정';

  @override
  String get adminPasswordChangeTitle => '관리자 비밀번호 변경';

  @override
  String get adminCurrentPasswordLabel => '현재 비밀번호';

  @override
  String get adminNewPasswordLabel => '새 비밀번호';

  @override
  String get adminConfirmPasswordLabel => '새 비밀번호 확인';

  @override
  String get adminPasswordChangeButton => '비밀번호 변경';

  @override
  String get adminPasswordChanging => '변경 중...';

  @override
  String get adminPasswordAllFieldsRequired => '모든 비밀번호를 4자리로 입력해주세요.';

  @override
  String get adminPasswordMismatch => '새 비밀번호가 일치하지 않습니다.';

  @override
  String get adminPasswordCurrentIncorrect => '현재 비밀번호가 일치하지 않습니다.';

  @override
  String get adminPasswordChangeSuccess => '비밀번호가 변경되었습니다.';

  @override
  String get adminPasswordChangeError => '비밀번호 변경 중 오류가 발생했습니다.';

  @override
  String get cancel => '취소';

  @override
  String get adminLanguageSelectionTitle => '언어 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get deviceTypeBP => '혈압';

  @override
  String get deviceTypeHS => '신장체중';

  @override
  String get deviceTypeVA => '시력';

  @override
  String get deviceTypeCM => '색각';

  @override
  String get deviceTypeBC => '체성분';

  @override
  String get deviceTypeBS => '혈당';

  @override
  String get deviceTypeHRV => '자율신경계(비접촉)';

  @override
  String get deviceTypeST => '자율신경계(접촉)';

  @override
  String get deviceTypeAL => '음주';

  @override
  String get deviceTypeMF => '메디폼';

  @override
  String get deviceTypeLU => '폐활량';

  @override
  String get deviceTypeOM => '기타';

  @override
  String get deviceSelectionTitle => '측정 가능 기기';

  @override
  String get noDevicesAvailable => '사용 가능한 측정 기기가 없습니다';

  @override
  String get bloodPressureSample => '혈압 샘플';

  @override
  String get bloodPressureResultTitle => '혈압측정 결과';

  @override
  String get systolicPressure => '수축기 혈압';

  @override
  String get diastolicPressure => '이완기 혈압';

  @override
  String get pulse => '맥박';

  @override
  String get mmHg => 'mmHg';

  @override
  String get bpm => 'bpm';

  @override
  String get resultHidden => '결과 숨김';

  @override
  String get resultHiddenMessage => '결과가 숨겨져 있습니다';

  @override
  String get videoArea => '영상 영역';

  @override
  String get remeasure => '재측정';

  @override
  String get sendMessage => '문자전송';

  @override
  String get sendMessagePending => '문자 전송 기능은 준비 중입니다.';

  @override
  String get bpStatusNormal => '정상';

  @override
  String get bpStatusCaution => '주의혈압';

  @override
  String get bpStatusPreHypertension => '전고혈압';

  @override
  String get bpStatusHypertension1 => '고혈압1기';

  @override
  String get bpStatusHypertension2 => '고혈압2기';

  @override
  String get bpStatusHypertension3 => '고혈압 3단계';

  @override
  String get resultShow => '결과 보기';

  @override
  String get resultHiddenGuide => '측정 결과를 문자전송으로 받아볼 수 있어요.';

  @override
  String get sendMessageSuccess => '측정 결과가 전송되었습니다.';

  @override
  String get sendMessageSuccessHighlight => '측정 결과';

  @override
  String get languageSelection => '언어 선택 (Language)';

  @override
  String get languageButton => 'Language';

  @override
  String get helpButton => '이용안내';

  @override
  String get languageKoreanNative => '한국어';

  @override
  String get languageKoreanEng => 'korean';

  @override
  String get languageEnglishNative => 'English';

  @override
  String get languageEnglishEng => 'English';

  @override
  String get guestPhoneInputTitle => '휴대폰 번호를 입력해주세요.\n측정 결과가 휴대폰으로 전송됩니다.';

  @override
  String get guestPhoneInputTitleHighlight1 => '휴대폰 번호';

  @override
  String get guestPhoneInputTitleHighlight2 => '측정 결과';

  @override
  String get agreeAllAndSend => '모두 동의하고 전송';

  @override
  String get termsAgreement => '*이용약관 동의';

  @override
  String get privacyPolicy => '개인정보 이용 동의 (필수)';

  @override
  String get termsOfService => '서비스이용약관동의(필수)';

  @override
  String get thirdPartyInfo => '제3자정보제공동의(필수)';

  @override
  String get viewDetails => '보기';

  @override
  String get bloodPressure => '혈압';

  @override
  String get systolicBloodPressure => '수축기 혈압';

  @override
  String get diastolicBloodPressure => '이완기 혈압';

  @override
  String get measurementResult => '측정 결과';

  @override
  String get requestAuth => '인증요청';

  @override
  String get verificationCode => '인증번호';

  @override
  String get enterVerificationCode => '인증번호를 입력해주세요.';

  @override
  String get enterPhoneNumberCorrectly => '휴대폰 번호를 올바르게 입력해주세요.';

  @override
  String get enterBirthday => '생년월일을 입력해주세요.';

  @override
  String get enterVerificationCode6Digits => '인증번호 6자리를 입력해주세요.';

  @override
  String get enterVerificationCode4Digits => '인증번호 4자리를 입력해주세요.';

  @override
  String get requestVerificationCodeFirst => '인증번호를 먼저 요청해주세요.';

  @override
  String get verificationFailed => '인증 실패';

  @override
  String get verificationCodeMismatch => '인증번호가 일치하지 않습니다.';

  @override
  String get authRequired => '인증 필요';

  @override
  String get requestAuthFirst => '인증요청을 먼저 진행해주세요.';

  @override
  String get error => '오류';

  @override
  String get authInfoNotFound => '인증 정보를 찾을 수 없습니다.';

  @override
  String get measurementInfoNotFound => '측정 정보를 찾을 수 없습니다.';

  @override
  String get enterCorrectPhoneNumber => '올바른 휴대폰 번호를 입력해주세요.';

  @override
  String get enterCorrectBirthday => '올바른 생년월일을 입력해주세요.';

  @override
  String get measurementResultNotFound => '측정 결과를 찾을 수 없습니다.';

  @override
  String get defaultKioskPlace => '메디터치 키오스크';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get homeScreen => '처음 화면';

  @override
  String get measurementGuide => '측정 안내';

  @override
  String get bloodPressureMeasurementGuide => '혈압 측정 안내';

  @override
  String get birthday => '생년월일';

  @override
  String get gender => '성별';

  @override
  String get pleaseEnter => '를 입력해주세요.';

  @override
  String get willBeSentToPhone => '가 휴대폰으로 전송됩니다.';

  @override
  String get am => '오전';

  @override
  String get pm => '오후';

  @override
  String get guestAuthRequiredTitle => '측정이 완료되었습니다.';

  @override
  String guestAuthRequiredMessage(String highlight) {
    return '결과 확인을 위해 $highlight를 입력해주세요.';
  }

  @override
  String get guestAuthRequiredHighlight => '사용자 정보';

  @override
  String get bluetoothDeviceManagement => '블루투스 기기 관리';

  @override
  String get bluetoothPairingGuide => '블루투스 페어링 안내';

  @override
  String get scanningDevices => '기기를 찾고 있습니다';

  @override
  String get deviceFound => '기기 발견';

  @override
  String get pairingRequired => '페어링이 필요합니다';

  @override
  String get bluetoothNotEnabled => '블루투스가 활성화되지 않았습니다';

  @override
  String get permissionRequired => '블루투스 권한이 필요합니다';

  @override
  String get connectDevice => '연결하기';

  @override
  String get disconnectDevice => '연결 해제';

  @override
  String get registerDevice => '등록';

  @override
  String get deleteDevice => '삭제';

  @override
  String get deviceConnectionSuccess => '연결 완료';

  @override
  String get deviceConnectionFailed => '연결 실패';

  @override
  String get noDevicesFound => '발견된 기기가 없습니다';

  @override
  String get rescan => '다시 검색';
}
