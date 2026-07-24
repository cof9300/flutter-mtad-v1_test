import 'package:dio/dio.dart';
import 'package:flutter_template/data/network/api_service_impl.dart';
import 'package:flutter_template/core/utils/token_storage_service.dart';

typedef Json = Map<String, dynamic>;
typedef Converter<T> = T Function(dynamic data);

abstract class ApiService {
  const ApiService();

  factory ApiService.create({TokenStorageService? tokenStorage}) =>
      ApiServiceImpl(tokenStorage: tokenStorage);

  void cancelRequests({CancelToken? cancelToken});

  Future<T> deleteJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
  });

  Future<T> getJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
    Map<String, String>? headers,
  });

  Future<T> putJson<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
  });

  Future<T> postJson<T>(
    String path, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
    Map<String, dynamic>? headers,
  });

  Future<T> postFormData<T>(
    String path, {
    required FormData data,
    Json? queryParameters,
    bool requiresAuthToken = false,
    Converter<T>? converter,
  });
}
