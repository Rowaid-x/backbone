import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage;

  AuthService(this._client, this._storage);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _client.dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    final access = resp.data['access'] as String;
    final refresh = resp.data['refresh'] as String;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
