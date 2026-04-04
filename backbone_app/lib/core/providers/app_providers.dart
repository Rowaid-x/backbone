import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/auth_service.dart';
import '../models/user_model.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage: storage);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.read(apiClientProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthService(client, storage);
});

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');
    if (token == null) return null;
    return _fetchMe();
  }

  Future<UserModel?> _fetchMe() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.dio.get('/users/me/');
      return UserModel.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(email, password);
      final user = await _fetchMe();
      state = AsyncData(user);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
