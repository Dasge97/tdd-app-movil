import 'package:dio/dio.dart';
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
    final token = await _storage.getAccessToken();
    if (token == null) {
      state = const AuthState();
      return;
    }
    try {
      final dio = _ref.read(apiClientProvider);
      final resp = await dio.get(ApiEndpoints.me);
      final user = User.fromJson(resp.data as Map<String, dynamic>);
      state = AuthState(user: user);
    } on DioException catch (e) {
      // Only log the user out when the server explicitly rejects credentials.
      // Network/timeout errors keep the existing session so a poor connection
      // doesn't kick the user back to login.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await _storage.clear();
        state = const AuthState();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo verificar la sesión. Reintenta más tarde.',
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: null);
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
        resp.data['accessToken'] as String,
        resp.data['refreshToken'] as String,
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
        resp.data['accessToken'] as String,
        resp.data['refreshToken'] as String,
      );
      final userResp = await dio.get(ApiEndpoints.me);
      final user =
          User.fromJson(userResp.data as Map<String, dynamic>);
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refreshUser(Map<String, dynamic> json) {
    final updated = User.fromJson(json);
    state = state.copyWith(user: updated);
  }

  Future<void> logout() async {
    try {
      final dio = _ref.read(apiClientProvider);
      final refreshToken = await _storage.getRefreshToken();
      await dio.post(
        ApiEndpoints.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
    } catch (_) {}
    await _storage.clear();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
        (ref) => AuthNotifier(ref));
