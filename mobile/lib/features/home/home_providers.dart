import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/debate.dart';
import '../../core/models/user.dart';

List<Debate> _parseDebates(dynamic data) {
  final list = data is List ? data : ((data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => Debate.fromJson(e as Map<String, dynamic>)).toList();
}

List<User> _parseUsers(dynamic data) {
  final list = data is List ? data : ((data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
}

final tickerDebatesProvider = FutureProvider.autoDispose<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debatesTicker);
  return _parseDebates(resp.data);
});

final todayDebatesProvider = FutureProvider.autoDispose<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debatesToday);
  return _parseDebates(resp.data);
});

final topTodayProvider = FutureProvider.autoDispose<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debatesTopToday);
  return _parseDebates(resp.data);
});

final topWeekProvider = FutureProvider.autoDispose<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debatesTopWeek);
  return _parseDebates(resp.data);
});

// familia: recibe username de persona o null (sin filtro)
final recentDebatesProvider =
    FutureProvider.autoDispose.family<List<Debate>, String?>((ref, persona) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(
    ApiEndpoints.debatesRecent,
    queryParameters: persona != null ? {'persona': persona} : null,
  );
  return _parseDebates(resp.data);
});

final protagonistasProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.usersProtagonistas);
  return _parseUsers(resp.data);
});

// Personas de IA para el filtro de Recientes
final aiPersonasProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.personas);
  return _parseUsers(resp.data);
});

// Persona seleccionada para el filtro de recientes (null = todos)
final selectedPersonaFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
