import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://76.13.213.26:8080/api',
);

const _storage = FlutterSecureStorage();

Dio buildDio() {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (err, handler) async {
      if (err.response?.statusCode == 401) {
        try {
          final refreshed = await _refreshToken(err.requestOptions);
          return handler.resolve(refreshed);
        } catch (_) {
          await _storage.deleteAll();
        }
      }
      handler.next(err);
    },
  ));

  return dio;
}

Future<Response<dynamic>> _refreshToken(RequestOptions original) async {
  final refresh = await _storage.read(key: 'refresh_token');
  if (refresh == null) throw Exception('No refresh token');

  final res = await Dio().post(
    '$_baseUrl/auth/refresh/',
    data: {'refresh': refresh},
  );

  final newAccess = res.data['access'] as String;
  final newRefresh = res.data['refresh'] as String? ?? refresh;
  await _storage.write(key: 'access_token', value: newAccess);
  await _storage.write(key: 'refresh_token', value: newRefresh);

  final retryOptions = original..headers['Authorization'] = 'Bearer $newAccess';
  return Dio().fetch(retryOptions);
}

final dioProvider = Provider<Dio>((ref) => buildDio());
