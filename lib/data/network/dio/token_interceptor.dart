import 'package:dio/dio.dart';
import 'package:flutter_template/core/utils/token_storage_service.dart';

class TokenInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage;

  TokenInterceptor(this._tokenStorage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = token;
    }
    return super.onRequest(options, handler);
  }
}

