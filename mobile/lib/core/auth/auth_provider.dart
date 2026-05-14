import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/user.dart';
import 'token_storage.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final TokenStorage _storage = TokenStorage();

  AuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        state = const AuthState();
        return;
      }
      final dio = _ref.read(apiClientProvider);
      final resp = await dio.get(ApiEndpoints.me);
      final user = User.fromJson(resp.data as Map<String, dynamic>);
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(apiClientProvider);
      final resp = await dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      await _storage.saveTokens(
        resp.data['access_token'] as String,
        resp.data['refresh_token'] as String,
      );
      final userResp = await dio.get(ApiEndpoints.me);
      final user =
          User.fromJson(userResp.data as Map<String, dynamic>);
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(
      String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(apiClientProvider);
      final resp = await dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      await _storage.saveTokens(
        resp.data['access_token'] as String,
        resp.data['refresh_token'] as String,
      );
      final userResp = await dio.get(ApiEndpoints.me);
      final user =
          User.fromJson(userResp.data as Map<String, dynamic>);
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await _storage.clear();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
        (ref) => AuthNotifier(ref));
