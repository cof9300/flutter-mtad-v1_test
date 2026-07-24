import 'package:flutter_template/data/network/api_service.dart';
import 'package:flutter_template/data/model/request/kiosk_auth_request.dart';
import 'package:flutter_template/data/model/response/kiosk_auth_response.dart';
import 'package:flutter_template/data/model/request/user_auth_request.dart';
import 'package:flutter_template/data/model/response/user_auth_response.dart';
import 'package:flutter_template/data/model/response/kiosk_option_response.dart';
import 'package:flutter_template/data/model/response/wait_page_option_response.dart';
import 'package:flutter_template/data/model/response/device_response.dart';
import 'package:flutter_template/data/model/request/send_sms_request.dart';
import 'package:flutter_template/data/model/request/send_mediform_request.dart';
import 'package:flutter_template/data/model/response/device_page_option_response.dart';
import 'package:flutter_template/data/model/request/set_result_request.dart';
import 'package:flutter_template/data/model/response/set_result_response.dart';
import 'package:flutter_template/data/model/request/update_result_user_request.dart';
import 'package:flutter_template/data/model/response/update_result_user_response.dart';
import 'package:flutter_template/data/model/response/result_page_option_response.dart';
import 'package:flutter_template/data/model/response/agreement_option_response.dart';
import 'package:flutter_template/data/model/response/kiosk_option_new_flag_response.dart';
import 'package:flutter_template/data/model/request/set_kiosk_option_use_flag_request.dart';
import 'package:flutter_template/data/model/response/set_kiosk_option_use_flag_response.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<KioskAuthResponse> kioskAuth(String kioskId) async {
    final request = KioskAuthRequest(kioskid: kioskId);

    final response = await _apiService.postJson<Map<String, dynamic>>(
      '/api/auth-kiosk',
      data: request.toJson(),
      requiresAuthToken: false,
    );

    final resultData = response['resultData'] as Map<String, dynamic>;
    return KioskAuthResponse.fromJson(resultData);
  }

  Future<KioskOptionResponse> getKioskOption(String token) async {
    final queryParameters = {'token': token};

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-kiosk-option',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    final resultData = response['resultData'] as Map<String, dynamic>;
    return KioskOptionResponse.fromJson(resultData);
  }

  Future<WaitPageOptionResponse> getWaitPageOption(String token) async {
    final queryParameters = {'token': token};

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-wait-page-option',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    final resultData = response['resultData'] as Map<String, dynamic>;
    return WaitPageOptionResponse.fromJson(resultData);
  }

  Future<UserAuthResponse> userAuth({
    required String phoneNumber,
    required String token,
    String? birthday,
    String? gender,
    String? serviceforce,
    String? type,
  }) async {
    final request = UserAuthRequest(
      userid: phoneNumber,
      type: type ?? 'PHONE',
      token: token,
      serviceforce: serviceforce,
      birthday: birthday,
      gender: gender,
    );

    final response = await _apiService.postJson<Map<String, dynamic>>(
      '/api/auth-user',
      data: request.toJson(),
      requiresAuthToken: false,
    );

    final resultData = response['resultData'] as Map<String, dynamic>;
    return UserAuthResponse.fromJson(resultData);
  }

  Future<void> sendSms({
    required String token,
    required String type,
    String? measureid,
    String? phonenumber,
    String? certnumber,
    String? result,
    String? date,
    String? place,
  }) async {
    final request = SendSmsRequest(
      token: token,
      type: type,
      measureid: measureid,
      phonenumber: phonenumber,
      certnumber: certnumber,
      result: result,
      date: date,
      place: place,
    );

    await _apiService.postJson<Map<String, dynamic>>(
      '/api/send-sms',
      data: request.toJson(),
      requiresAuthToken: true,
    );
  }

  Future<DeviceListResponse> getDevice(String token) async {
    final queryParameters = {'token': token};

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-device',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    final resultData = response['resultData'];

    if (resultData is Map<String, dynamic>) {
      final deviceList = resultData['device'] as List<dynamic>?;
      if (deviceList != null && deviceList.isNotEmpty) {
        return DeviceListResponse.fromJson(deviceList);
      }
    }

    return DeviceListResponse(devices: []);
  }

  Future<DevicePageOptionResponse> getDevicePageOption({
    required String token,
    required String device,
  }) async {
    final queryParameters = {
      'token': token,
      'device': device,
    };

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-device-page-option',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    return DevicePageOptionResponse.fromJson(response);
  }

  Future<SetResultResponse> setResult({
    required String token,
    required String measureid,
    required String device,
    required Map<String, dynamic> result,
    String serviceforce = 'false',
  }) async {
    final request = SetResultRequest(
      token: token,
      measureid: measureid,
      device: device,
      result: result,
      serviceforce: serviceforce,
    );

    final response = await _apiService.postJson<Map<String, dynamic>>(
      '/api/set-result',
      data: request.toJson(),
      requiresAuthToken: false,
    );

    return SetResultResponse.fromJson(response);
  }

  Future<ResultPageOptionResponse> getResultPageOption(String token) async {
    final queryParameters = {'token': token};

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-result-page-option',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    return ResultPageOptionResponse.fromJson(response);
  }

  Future<AgreementOptionResponse> getAgreementOption(String token) async {
    final queryParameters = {'token': token};

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-agreement-option',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    return AgreementOptionResponse.fromJson(response);
  }

  Future<UpdateResultUserResponse> updateResultUser({
    required String token,
    required String measureid,
    required String userid,
    required String type,
    String? birth,
    String? gender,
  }) async {
    final request = UpdateResultUserRequest(
      token: token,
      measureid: measureid,
      userid: userid,
      type: type,
      birth: birth,
      gender: gender,
    );

    final response = await _apiService.postJson<Map<String, dynamic>>(
      '/api/update-result-user',
      data: request.toJson(),
      requiresAuthToken: false,
    );

    return UpdateResultUserResponse.fromJson(response);
  }

  Future<KioskOptionNewFlagResponse> getKioskOptionNewFlag(String token) async {
    final queryParameters = {'token': token};

    final response = await _apiService.getJson<Map<String, dynamic>>(
      '/api/get-kiosk-option-new-flag',
      queryParameters: queryParameters,
      requiresAuthToken: false,
    );

    return KioskOptionNewFlagResponse.fromJson(response);
  }

  Future<SetKioskOptionUseFlagResponse> setKioskOptionUseFlag({
    required String token,
    required String type,
  }) async {
    final request = SetKioskOptionUseFlagRequest(
      token: token,
      type: type,
    );

    final response = await _apiService.postJson<Map<String, dynamic>>(
      '/api/set-kiosk-option-use-flag',
      data: request.toJson(),
      requiresAuthToken: false,
    );

    return SetKioskOptionUseFlagResponse.fromJson(response);
  }

  Future<void> sendMediform({
    required String token,
    required String measureid,
  }) async {
    final request = SendMediformRequest(
      token: token,
      measureid: measureid,
    );

    await _apiService.postJson<Map<String, dynamic>>(
      '/api/send-mediform',
      data: request.toJson(),
      requiresAuthToken: true,
    );
  }
}
