import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';

const _storage = FlutterSecureStorage();

class AuthState {
  final UserModel? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;
  AuthState copyWith({UserModel? user, bool? loading, String? error}) =>
      AuthState(user: user ?? this.user, loading: loading ?? this.loading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> init() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;
    try {
      final res = await _ref.read(dioProvider).get('/auth/me/');
      state = AuthState(user: UserModel.fromJson(res.data as Map<String, dynamic>));
    } catch (_) {
      await _storage.deleteAll();
    }
  }

  Future<void> login(String email) async {
    state = const AuthState(loading: true);
    try {
      final res = await _ref.read(dioProvider).post(
        '/auth/login/',
        data: {'email': email.toLowerCase().trim()},
      );
      final data = res.data as Map<String, dynamic>;
      await _storage.write(key: 'access_token', value: data['access'] as String);
      await _storage.write(key: 'refresh_token', value: data['refresh'] as String);
      state = AuthState(user: UserModel.fromJson(data['user'] as Map<String, dynamic>));
    } catch (e) {
      final msg = _parseError(e);
      state = AuthState(error: msg);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      await _ref.read(dioProvider).post('/auth/logout/', data: {'refresh': refresh});
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }

  String _parseError(Object e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'Something went wrong';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
