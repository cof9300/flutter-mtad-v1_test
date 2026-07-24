// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Flutter Template';

  @override
  String get headerTitle => 'Chăm sóc sức khỏe thông minh';

  @override
  String get touchScreenMessage => 'Vui lòng chạm vào màn hình!';

  @override
  String get authTitle =>
      'Vui lòng nhập <b>số người dùng</b> hoặc <b>số điện thoại di động</b>\nhoặc quét <b>mã vạch người dùng</b> hoặc <b>mã QR</b> của bạn.';

  @override
  String get authInputHint => 'Nhập số người dùng hoặc số điện thoại';

  @override
  String get authClearAll => 'Xóa tất cả';

  @override
  String get authConfirm => 'Xác nhận';

  @override
  String get loadingDefault => 'Đang xử lý...';

  @override
  String get systemErrorTitle => 'Lỗi hệ thống';

  @override
  String get systemErrorMessage =>
      'Đã xảy ra lỗi hệ thống.\nVui lòng liên hệ với quản trị viên.';

  @override
  String get contactAdministrator => 'Vui lòng liên hệ với quản trị viên.';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get progressTitle => 'Đang tiến hành.';

  @override
  String get progressMessage => 'Vui lòng đợi một chút.';

  @override
  String get invalidPhoneFormatTitle => 'Lỗi nhập liệu';

  @override
  String get invalidPhoneFormat =>
      'Định dạng số điện thoại không đúng.\nVui lòng nhập 11 chữ số.';

  @override
  String get noMemberFound => 'Không tìm thấy thông tin thành viên phù hợp.';

  @override
  String registerQuestion(String highlight) {
    return 'Bạn có muốn $highlight với số này không?';
  }

  @override
  String get registerHighlight => 'đăng ký';

  @override
  String get registerPrefix => 'Bạn có muốn';

  @override
  String get registerSuffix => 'với số này không?';

  @override
  String get measurementHighlight => 'đo';

  @override
  String get measurementQuestion => 'Bạn có muốn đo không?';

  @override
  String get phoneCheckMessage => 'Vui lòng kiểm tra số điện thoại của bạn.';

  @override
  String get no => 'Không';

  @override
  String get yes => 'Có';

  @override
  String get registrationCompleteTitle => 'Liên kết đăng ký đã được gửi.';

  @override
  String get registrationCompleteMessage =>
      'Vui lòng <c>đăng ký</c> trên điện thoại di động của bạn\nvà tiến hành đo.';

  @override
  String get userConfirmQuestion => 'Đây có phải là bạn không?';

  @override
  String get userConfirmYes => 'Vâng, đúng vậy';

  @override
  String get userConfirmNo => 'Không phải';

  @override
  String get adminPasswordTitle => 'Mật khẩu quản trị viên';

  @override
  String get adminPasswordErrorTitle => 'Lỗi';

  @override
  String get adminPasswordErrorMessage => 'Mật khẩu quản trị viên không đúng.';

  @override
  String get adminSettingsTitle => 'Cài đặt quản trị viên';

  @override
  String get adminPasswordChangeTitle => 'Thay đổi mật khẩu quản trị viên';

  @override
  String get adminCurrentPasswordLabel => 'Mật khẩu hiện tại';

  @override
  String get adminNewPasswordLabel => 'Mật khẩu mới';

  @override
  String get adminConfirmPasswordLabel => 'Xác nhận mật khẩu mới';

  @override
  String get adminPasswordChangeButton => 'Thay đổi mật khẩu';

  @override
  String get adminPasswordChanging => 'Đang thay đổi...';

  @override
  String get adminPasswordAllFieldsRequired =>
      'Vui lòng nhập tất cả mật khẩu là 4 chữ số.';

  @override
  String get adminPasswordMismatch => 'Mật khẩu mới không khớp.';

  @override
  String get adminPasswordCurrentIncorrect => 'Mật khẩu hiện tại không đúng.';

  @override
  String get adminPasswordChangeSuccess => 'Mật khẩu đã được thay đổi.';

  @override
  String get adminPasswordChangeError => 'Đã xảy ra lỗi khi thay đổi mật khẩu.';

  @override
  String get cancel => 'Hủy';

  @override
  String get adminLanguageSelectionTitle => 'Cài đặt ngôn ngữ';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get deviceTypeBP => 'Huyết áp';

  @override
  String get deviceTypeHS => 'Chiều cao & Cân nặng';

  @override
  String get deviceTypeVA => 'Thị lực';

  @override
  String get deviceTypeCM => 'Thị giác màu';

  @override
  String get deviceTypeBC => 'Thành phần cơ thể';

  @override
  String get deviceTypeBS => 'Đường huyết';

  @override
  String get deviceTypeHRV => 'Hệ thần kinh tự chủ (Không tiếp xúc)';

  @override
  String get deviceTypeST => 'Hệ thần kinh tự chủ (Tiếp xúc)';

  @override
  String get deviceTypeAL => 'Rượu';

  @override
  String get deviceTypeHC => 'Cân đo chiều cao';

  @override
  String get deviceTypeMF => 'Mediform';

  @override
  String get deviceTypeLU => 'Dung tích phổi';

  @override
  String get deviceTypeOM => 'Khác';

  @override
  String get deviceSelectionTitle => 'Thiết bị có sẵn';

  @override
  String get noDevicesAvailable => 'Không có thiết bị nào có sẵn';

  @override
  String get bloodPressureSample => 'Mẫu huyết áp';

  @override
  String get bloodPressureResultTitle => 'Kết quả đo huyết áp';

  @override
  String get systolicPressure => 'Huyết áp tâm thu';

  @override
  String get diastolicPressure => 'Huyết áp tâm trương';

  @override
  String get pulse => 'Mạch';

  @override
  String get mmHg => 'mmHg';

  @override
  String get bpm => 'bpm';

  @override
  String get resultHidden => 'Ẩn kết quả';

  @override
  String get resultHiddenMessage => 'Kết quả đã được ẩn';

  @override
  String get videoArea => 'Khu vực video';

  @override
  String get remeasure => 'Đo lại';

  @override
  String get sendMessage => 'Gửi tin nhắn';

  @override
  String get sendMessagePending => 'Tính năng gửi tin nhắn đang được chuẩn bị.';

  @override
  String get bpStatusNormal => 'Bình thường';

  @override
  String get bpStatusCaution => 'Cảnh báo';

  @override
  String get bpStatusPreHypertension => 'Tiền tăng huyết áp';

  @override
  String get bpStatusHypertension1 => 'Tăng huyết áp Giai đoạn 1';

  @override
  String get bpStatusHypertension2 => 'Tăng huyết áp Giai đoạn 2';

  @override
  String get bpStatusHypertension3 => 'Tăng huyết áp Giai đoạn 3';

  @override
  String get heightWeightResultTitle => 'Kết quả đo chiều cao & cân nặng';

  @override
  String get bmiStatusUnderweight => 'Thiếu cân';

  @override
  String get bmiStatusNormal => 'Bình thường';

  @override
  String get bmiStatusPreObese => 'Tiền béo phì';

  @override
  String get bmiStatusObese1 => 'Béo phì độ I';

  @override
  String get bmiStatusObese2 => 'Béo phì độ II';

  @override
  String get bmiStatusObese3 => 'Béo phì độ III';

  @override
  String get resultShow => 'Hiển thị kết quả';

  @override
  String get resultHiddenGuide =>
      'Bạn có thể nhận kết quả đo qua tin nhắn văn bản.';

  @override
  String get sendMessageSuccess => 'Kết quả đo đã được gửi.';

  @override
  String get sendMessageSuccessHighlight => 'Kết quả đo';

  @override
  String get sendMessageSuccessSuffix => ' đã được gửi.';

  @override
  String get languageSelection => 'Chọn ngôn ngữ';

  @override
  String get languageButton => 'Language';

  @override
  String get helpButton => 'Hướng dẫn sử dụng';

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
      'Vui lòng nhập số điện thoại của bạn.\nKết quả đo sẽ được gửi đến điện thoại của bạn.';

  @override
  String get guestPhoneInputTitleHighlight1 => 'số điện thoại';

  @override
  String get guestPhoneInputTitleHighlight2 => 'Kết quả đo';

  @override
  String get agreeAllAndSend => 'Đồng ý tất cả và gửi';

  @override
  String get termsAgreement => '*Thỏa thuận điều khoản';

  @override
  String get privacyPolicy => 'Chính sách bảo mật (Bắt buộc)';

  @override
  String get termsOfService => 'Điều khoản dịch vụ (Bắt buộc)';

  @override
  String get thirdPartyInfo => 'Thông tin bên thứ ba (Bắt buộc)';

  @override
  String get sensitiveInfo => 'Thông tin nhạy cảm (Bắt buộc)';

  @override
  String get viewDetails => 'Xem';

  @override
  String get agreementContentUnavailable =>
      'Không tải được nội dung điều khoản. Vui lòng thử lại sau.';

  @override
  String get bloodPressure => 'Huyết áp';

  @override
  String get systolicBloodPressure => 'Huyết áp tâm thu';

  @override
  String get diastolicBloodPressure => 'Huyết áp tâm trương';

  @override
  String get measurementResult => 'Kết quả đo';

  @override
  String get requestAuth => 'Yêu cầu xác thực';

  @override
  String get verificationCode => 'Mã xác thực';

  @override
  String get enterVerificationCode => 'Vui lòng nhập mã xác thực.';

  @override
  String get enterPhoneNumberCorrectly => 'Vui lòng nhập số điện thoại đúng.';

  @override
  String get enterBirthday => 'Vui lòng nhập ngày sinh.';

  @override
  String get enterVerificationCode6Digits =>
      'Vui lòng nhập mã xác thực 6 chữ số.';

  @override
  String get enterVerificationCode4Digits =>
      'Vui lòng nhập mã xác thực 4 chữ số.';

  @override
  String get requestVerificationCodeFirst =>
      'Vui lòng yêu cầu mã xác thực trước.';

  @override
  String get verificationFailed => 'Xác thực thất bại';

  @override
  String get verificationCodeMismatch => 'Mã xác thực không khớp.';

  @override
  String get authRequired => 'Yêu cầu xác thực';

  @override
  String get requestAuthFirst => 'Vui lòng yêu cầu xác thực trước.';

  @override
  String get error => 'Lỗi';

  @override
  String get authInfoNotFound => 'Không tìm thấy thông tin xác thực.';

  @override
  String get measurementInfoNotFound => 'Không tìm thấy thông tin đo.';

  @override
  String get enterCorrectPhoneNumber => 'Vui lòng nhập số điện thoại đúng.';

  @override
  String get enterCorrectBirthday => 'Vui lòng nhập ngày sinh đúng.';

  @override
  String get measurementResultNotFound => 'Không tìm thấy kết quả đo.';

  @override
  String get defaultKioskPlace => 'Meditech Kiosk';

  @override
  String get male => 'Nam';

  @override
  String get female => 'Nữ';

  @override
  String get homeScreen => 'Màn hình chính';

  @override
  String get measurementGuide => 'Hướng dẫn đo';

  @override
  String get bloodPressureMeasurementGuide => 'Hướng dẫn đo huyết áp';

  @override
  String get birthday => 'Ngày sinh';

  @override
  String get gender => 'Giới tính';

  @override
  String get pleaseEnter => 'Vui lòng nhập';

  @override
  String get willBeSentToPhone => 'sẽ được gửi đến điện thoại của bạn.';

  @override
  String get am => 'Sáng';

  @override
  String get pm => 'Chiều';

  @override
  String get guestAuthRequiredTitle => 'Đo đã hoàn thành.';

  @override
  String guestAuthRequiredMessage(String highlight) {
    return 'Vui lòng nhập $highlight để xem kết quả.';
  }

  @override
  String get guestAuthRequiredHighlight => 'thông tin người dùng';

  @override
  String get bluetoothDeviceManagement => 'Quản lý thiết bị Bluetooth';

  @override
  String get bluetoothPairingGuide => 'Hướng dẫn ghép nối Bluetooth';

  @override
  String get scanningDevices => 'Đang tìm kiếm thiết bị';

  @override
  String get deviceFound => 'Đã tìm thấy thiết bị';

  @override
  String get pairingRequired => 'Yêu cầu ghép nối';

  @override
  String get bluetoothNotEnabled => 'Bluetooth chưa được bật';

  @override
  String get permissionRequired => 'Yêu cầu quyền Bluetooth';

  @override
  String get connectDevice => 'Kết nối';

  @override
  String get disconnectDevice => 'Ngắt kết nối';

  @override
  String get registerDevice => 'Đăng ký';

  @override
  String get deleteDevice => 'Xóa';

  @override
  String get deviceConnectionSuccess => 'Kết nối thành công';

  @override
  String get deviceConnectionFailed => 'Kết nối thất bại';

  @override
  String get noDevicesFound => 'Không tìm thấy thiết bị';

  @override
  String get rescan => 'Quét lại';

  @override
  String get deviceConnectionNotConfirmed =>
      'Kết nối thiết bị chưa được xác nhận';

  @override
  String get deviceConnectionCheckMessage =>
      'Vui lòng kiểm tra thiết bị và cổng.';

  @override
  String get alcoResultTitle => 'Kết quả đo nồng độ cồn';

  @override
  String get alcoResultLoading => 'Đang nhận dữ liệu kết quả...';

  @override
  String get alcoResultHidden => 'Kết quả đã được ẩn.';

  @override
  String get alcoResultPass => 'Kết quả đo bình thường.';

  @override
  String get alcoResultPassSub => '(Khi nồng độ cồn trong máu dưới 0.030%)';

  @override
  String get alcoResultFailGuide =>
      'Vui lòng làm theo hướng dẫn của quản trị viên.';

  @override
  String get alcoResultFailSub =>
      '(Khi nồng độ cồn trong máu từ 0.030% trở lên)';

  @override
  String get hwHeightLabel => 'Chiều cao';

  @override
  String get hwWeightLabel => 'Cân nặng';

  @override
  String get hwBmiLabel => 'BMI';
}
