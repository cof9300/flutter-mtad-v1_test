import 'package:dio/dio.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/core/utils/token_storage_service.dart';
import 'api_service.dart';
import 'dio/dio_service.dart';
import 'dio/logging_interceptor.dart';
import 'dio/token_interceptor.dart';
import 'network_exception.dart';

class ApiServiceImpl implements ApiService {
  ApiServiceImpl({
    String? baseUrl,
    Duration? timeout,
    TokenStorageService? tokenStorage,
  })  : _tokenStorage = tokenStorage,
        baseUrl = baseUrl ?? Config.baseUrl,
        timeout = timeout ?? Config.timeout;

  final String baseUrl;
  final Duration timeout;
  final TokenStorageService? _tokenStorage;

  DioService? _dioService;
  DioService get dioService => _dioService ??= DioService(
        BaseOptions(
          baseUrl: baseUrl,
          sendTimeout: timeout,
          connectTimeout: timeout,
          receiveTimeout: timeout,
        ),
        [
          if (_tokenStorage != null) TokenInterceptor(_tokenStorage),
          if (Config.enableLogRequestInfo) LoggingInterceptor(),
        ],
      );

  Future<T> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required String method,
    required String contentType,
    bool requiresAuthToken = false,
    Converter<T>? converter,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final Map<String, dynamic> finalHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        ...?headers,
      };

      final Response response = await dioService.request(
        path,
        data: data,
        options: Options(
          method: method,
          contentType: contentType,
          headers: finalHeaders,
        ),
        queryParameters: queryParameters,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      if (converter != null) {
        return converter.call(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (error) {
      throw NetworkException.getException(error);
    }
  }

  @override
  void cancelRequests({CancelToken? cancelToken}) =>
      dioService.cancelRequests(cancelToken: cancelToken);

  @override
  Future<T> deleteJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'DELETE',
        contentType: Headers.jsonContentType,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> getJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
    Map<String, String>? headers,
  }) =>
      request(
        path,
        method: 'GET',
        contentType: Headers.jsonContentType,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
        headers: headers,
      );

  @override
  Future<T> putJson<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'PUT',
        contentType: Headers.jsonContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> postJson<T>(
    String path, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
    Map<String, dynamic>? headers,
  }) =>
      request(
        path,
        method: 'POST',
        contentType: Headers.jsonContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
        headers: headers,
      );

  @override
  Future<T> postFormData<T>(
    String path, {
    required FormData data,
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'POST',
        contentType: Headers.multipartFormDataContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );
}
