// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flutter 模板';

  @override
  String get headerTitle => '智能健康管理';

  @override
  String get touchScreenMessage => '请触摸屏幕！';

  @override
  String get authTitle =>
      '请输入您的<b>用户编号</b>或<b>手机号码</b>\n或扫描您的<b>用户条形码</b>或<b>二维码</b>。';

  @override
  String get authInputHint => '请输入用户编号或手机号码';

  @override
  String get authClearAll => '全部清除';

  @override
  String get authConfirm => '确认';

  @override
  String get loadingDefault => '处理中...';

  @override
  String get systemErrorTitle => '系统错误';

  @override
  String get systemErrorMessage => '系统发生错误。\n请联系管理员。';

  @override
  String get contactAdministrator => '请联系管理员。';

  @override
  String get confirm => '确认';

  @override
  String get progressTitle => '进行中。';

  @override
  String get progressMessage => '请稍候。';

  @override
  String get invalidPhoneFormatTitle => '输入错误';

  @override
  String get invalidPhoneFormat => '电话号码格式不正确。\n请输入11位数字。';

  @override
  String get noMemberFound => '未找到匹配的会员信息。';

  @override
  String registerQuestion(String highlight) {
    return '您想用此号码$highlight吗？';
  }

  @override
  String get registerHighlight => '注册';

  @override
  String get registerPrefix => '您想用此号码';

  @override
  String get registerSuffix => '吗？';

  @override
  String get measurementHighlight => '测量';

  @override
  String get measurementQuestion => '您想进行测量吗？';

  @override
  String get phoneCheckMessage => '请检查您的手机号码。';

  @override
  String get no => '否';

  @override
  String get yes => '是';

  @override
  String get registrationCompleteTitle => '注册链接已发送。';

  @override
  String get registrationCompleteMessage => '请在手机上<c>注册</c>\n然后进行测量。';

  @override
  String get userConfirmQuestion => '是您本人吗？';

  @override
  String get userConfirmYes => '是的，正确';

  @override
  String get userConfirmNo => '不是';

  @override
  String get adminPasswordTitle => '管理员密码';

  @override
  String get adminPasswordErrorTitle => '错误';

  @override
  String get adminPasswordErrorMessage => '管理员密码不正确。';

  @override
  String get adminSettingsTitle => '管理员设置';

  @override
  String get adminPasswordChangeTitle => '更改管理员密码';

  @override
  String get adminCurrentPasswordLabel => '当前密码';

  @override
  String get adminNewPasswordLabel => '新密码';

  @override
  String get adminConfirmPasswordLabel => '确认新密码';

  @override
  String get adminPasswordChangeButton => '更改密码';

  @override
  String get adminPasswordChanging => '更改中...';

  @override
  String get adminPasswordAllFieldsRequired => '请输入所有密码为4位数字。';

  @override
  String get adminPasswordMismatch => '新密码不匹配。';

  @override
  String get adminPasswordCurrentIncorrect => '当前密码不正确。';

  @override
  String get adminPasswordChangeSuccess => '密码已更改。';

  @override
  String get adminPasswordChangeError => '更改密码时发生错误。';

  @override
  String get cancel => '取消';

  @override
  String get adminLanguageSelectionTitle => '语言设置';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get deviceTypeBP => '血压';

  @override
  String get deviceTypeHS => '身高体重';

  @override
  String get deviceTypeVA => '视力';

  @override
  String get deviceTypeCM => '色觉';

  @override
  String get deviceTypeBC => '体成分';

  @override
  String get deviceTypeBS => '血糖';

  @override
  String get deviceTypeHRV => '自主神经（非接触）';

  @override
  String get deviceTypeST => '自主神经（接触）';

  @override
  String get deviceTypeAL => '酒精';

  @override
  String get deviceTypeHC => '身高体重秤';

  @override
  String get deviceTypeMF => 'Mediform';

  @override
  String get deviceTypeLU => '肺活量';

  @override
  String get deviceTypeOM => '其他';

  @override
  String get deviceSelectionTitle => '可用设备';

  @override
  String get noDevicesAvailable => '没有可用设备';

  @override
  String get bloodPressureSample => '血压样本';

  @override
  String get bloodPressureResultTitle => '血压测量结果';

  @override
  String get systolicPressure => '收缩压';

  @override
  String get diastolicPressure => '舒张压';

  @override
  String get pulse => '脉搏';

  @override
  String get mmHg => 'mmHg';

  @override
  String get bpm => 'bpm';

  @override
  String get resultHidden => '隐藏结果';

  @override
  String get resultHiddenMessage => '结果已隐藏';

  @override
  String get videoArea => '视频区域';

  @override
  String get remeasure => '重新测量';

  @override
  String get sendMessage => '发送短信';

  @override
  String get sendMessagePending => '短信发送功能正在准备中。';

  @override
  String get bpStatusNormal => '正常';

  @override
  String get bpStatusCaution => '注意';

  @override
  String get bpStatusPreHypertension => '高血压前期';

  @override
  String get bpStatusHypertension1 => '高血压1期';

  @override
  String get bpStatusHypertension2 => '高血压2期';

  @override
  String get bpStatusHypertension3 => '高血压3期';

  @override
  String get heightWeightResultTitle => '身高体重测量结果';

  @override
  String get bmiStatusUnderweight => '体重过轻';

  @override
  String get bmiStatusNormal => '正常';

  @override
  String get bmiStatusPreObese => '超重前期';

  @override
  String get bmiStatusObese1 => '肥胖I级';

  @override
  String get bmiStatusObese2 => '肥胖II级';

  @override
  String get bmiStatusObese3 => '肥胖III级';

  @override
  String get resultShow => '显示结果';

  @override
  String get resultHiddenGuide => '您可以通过短信接收测量结果。';

  @override
  String get sendMessageSuccess => '测量结果已发送。';

  @override
  String get sendMessageSuccessHighlight => '测量结果';

  @override
  String get sendMessageSuccessSuffix => '已发送。';

  @override
  String get languageSelection => '语言选择';

  @override
  String get languageButton => 'Language';

  @override
  String get helpButton => '使用指南';

  @override
  String get languageKoreanNative => '한국어';

  @override
  String get languageKoreanEng => 'korean';

  @override
  String get languageEnglishNative => 'English';

  @override
  String get languageEnglishEng => 'English';

  @override
  String get guestPhoneInputTitle => '请输入您的手机号码。\n测量结果将发送到您的手机。';

  @override
  String get guestPhoneInputTitleHighlight1 => '手机号码';

  @override
  String get guestPhoneInputTitleHighlight2 => '测量结果';

  @override
  String get agreeAllAndSend => '全部同意并发送';

  @override
  String get termsAgreement => '*条款协议';

  @override
  String get privacyPolicy => '隐私政策（必填）';

  @override
  String get termsOfService => '服务条款（必填）';

  @override
  String get thirdPartyInfo => '第三方信息（必填）';

  @override
  String get sensitiveInfo => '敏感信息（必填）';

  @override
  String get viewDetails => '查看';

  @override
  String get agreementContentUnavailable => '无法加载协议内容，请稍后重试。';

  @override
  String get bloodPressure => '血压';

  @override
  String get systolicBloodPressure => '收缩压';

  @override
  String get diastolicBloodPressure => '舒张压';

  @override
  String get measurementResult => '测量结果';

  @override
  String get requestAuth => '请求认证';

  @override
  String get verificationCode => '验证码';

  @override
  String get enterVerificationCode => '请输入验证码。';

  @override
  String get enterPhoneNumberCorrectly => '请正确输入手机号码。';

  @override
  String get enterBirthday => '请输入生日。';

  @override
  String get enterVerificationCode6Digits => '请输入6位验证码。';

  @override
  String get enterVerificationCode4Digits => '请输入4位验证码。';

  @override
  String get requestVerificationCodeFirst => '请先请求验证码。';

  @override
  String get verificationFailed => '验证失败';

  @override
  String get verificationCodeMismatch => '验证码不匹配。';

  @override
  String get authRequired => '需要认证';

  @override
  String get requestAuthFirst => '请先请求认证。';

  @override
  String get error => '错误';

  @override
  String get authInfoNotFound => '未找到认证信息。';

  @override
  String get measurementInfoNotFound => '未找到测量信息。';

  @override
  String get enterCorrectPhoneNumber => '请输入正确的手机号码。';

  @override
  String get enterCorrectBirthday => '请输入正确的生日。';

  @override
  String get measurementResultNotFound => '未找到测量结果。';

  @override
  String get defaultKioskPlace => 'Meditech 自助服务终端';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get homeScreen => '首页';

  @override
  String get measurementGuide => '测量指南';

  @override
  String get bloodPressureMeasurementGuide => '血压测量指南';

  @override
  String get birthday => '生日';

  @override
  String get gender => '性别';

  @override
  String get pleaseEnter => '请输入';

  @override
  String get willBeSentToPhone => '将发送到您的手机。';

  @override
  String get am => '上午';

  @override
  String get pm => '下午';

  @override
  String get guestAuthRequiredTitle => '测量完成。';

  @override
  String guestAuthRequiredMessage(String highlight) {
    return '请输入$highlight以查看结果。';
  }

  @override
  String get guestAuthRequiredHighlight => '用户信息';

  @override
  String get bluetoothDeviceManagement => '蓝牙设备管理';

  @override
  String get bluetoothPairingGuide => '蓝牙配对指南';

  @override
  String get scanningDevices => '正在搜索设备';

  @override
  String get deviceFound => '找到设备';

  @override
  String get pairingRequired => '需要配对';

  @override
  String get bluetoothNotEnabled => '蓝牙未启用';

  @override
  String get permissionRequired => '需要蓝牙权限';

  @override
  String get connectDevice => '连接';

  @override
  String get disconnectDevice => '断开连接';

  @override
  String get registerDevice => '注册';

  @override
  String get deleteDevice => '删除';

  @override
  String get deviceConnectionSuccess => '连接成功';

  @override
  String get deviceConnectionFailed => '连接失败';

  @override
  String get noDevicesFound => '未找到设备';

  @override
  String get rescan => '重新扫描';

  @override
  String get deviceConnectionNotConfirmed => '设备连接未确认';

  @override
  String get deviceConnectionCheckMessage => '请检查设备和端口。';

  @override
  String get alcoResultTitle => '酒精测试结果';

  @override
  String get alcoResultLoading => '正在接收结果数据...';

  @override
  String get alcoResultHidden => '结果已隐藏。';

  @override
  String get alcoResultPass => '测量结果正常。';

  @override
  String get alcoResultPassSub => '（血液酒精浓度低于0.030%时）';

  @override
  String get alcoResultFailGuide => '请接受管理员的指导。';

  @override
  String get alcoResultFailSub => '（血液酒精浓度达到0.030%或以上时）';

  @override
  String get hwHeightLabel => '身高';

  @override
  String get hwWeightLabel => '体重';

  @override
  String get hwBmiLabel => '体质量';
}
