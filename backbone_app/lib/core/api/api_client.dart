import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

String get _baseUrl {
  if (kIsWeb) return 'http://localhost:8000/api';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
  } catch (_) {}
  return 'http://localhost:8000/api';
}

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // Refresh lock: prevents concurrent 401s from double-refreshing
  Completer<String>? _refreshCompleter;

  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl)),
        _storage = storage ?? const FlutterSecureStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // 401 — attempt token refresh
    if (_refreshCompleter != null) {
      // Another request is already refreshing — wait for it
      try {
        final newToken = await _refreshCompleter!.future;
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final response = await _dio.fetch(opts);
        handler.resolve(response);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    _refreshCompleter = Completer<String>();
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _refreshCompleter!.completeError('no_refresh_token');
        _refreshCompleter = null;
        handler.next(err);
        return;
      }

      final resp = await Dio(BaseOptions(baseUrl: _baseUrl))
          .post('/auth/refresh/', data: {'refresh': refreshToken});

      final newAccess = resp.data['access'] as String;
      await _storage.write(key: 'access_token', value: newAccess);
      _refreshCompleter!.complete(newAccess);
      _refreshCompleter = null;

      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await _dio.fetch(opts);
      handler.resolve(retried);
    } catch (_) {
      _refreshCompleter?.completeError('refresh_failed');
      _refreshCompleter = null;
      await _storage.deleteAll();
      handler.next(err);
    }
  }

  Dio get dio => _dio;
}
