import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import '../auth/token_storage.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final storage = TokenStorage();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        try {
          final refreshToken = await storage.getRefreshToken();
          if (refreshToken == null) {
            await storage.clear();
            return handler.next(error);
          }
          final refreshDio =
              Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final resp = await refreshDio.post(
            ApiEndpoints.refresh,
            options: Options(
                headers: {'Authorization': 'Bearer $refreshToken'}),
          );
          await storage.saveTokens(
            resp.data['accessToken'] as String,
            resp.data['refreshToken'] as String,
          );
          error.requestOptions.headers['Authorization'] =
              'Bearer ${resp.data['accessToken']}';
          final retry = await dio.fetch(error.requestOptions);
          return handler.resolve(retry);
        } catch (_) {
          await storage.clear();
        }
      }
      handler.next(error);
    },
  ));
  return dio;
});
