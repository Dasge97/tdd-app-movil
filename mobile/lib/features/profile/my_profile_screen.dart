import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/debate.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/debate_card.dart';

final _favoritesProvider = FutureProvider<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.myFavorites);
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => Debate.fromJson(e as Map<String, dynamic>)).toList();
});

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final favAsync = ref.watch(_favoritesProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero section
          Container(
            color: TddColors.bgElev,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                Avatar(
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  size: 80,
                ),
                const SizedBox(height: 14),
                Text(
                  user.username,
                  style: TddTypography.serif(size: 22, weight: FontWeight.w500),
                ),
                if (user.profileTagline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.profileTagline!,
                    textAlign: TextAlign.center,
                    style: TddTypography.sans(
                        size: 13, color: TddColors.text3,
                        style: FontStyle.italic),
                  ),
                ],
                if (user.location != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TddColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: TddColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: TddColors.text3),
                        const SizedBox(width: 4),
                        Text(
                          user.location!,
                          style: TddTypography.mono(
                              size: 10, color: TddColors.text3),
                        ),
                      ],
                    ),
                  ),
                ],
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TddTypography.sans(
                        size: 14, color: TddColors.text2, height: 1.5),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/home/profile/edit'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                  ),
                  child: const Text('Editar perfil'),
                ),
              ],
            ),
          ),
          // Stats row
          Container(
            decoration: const BoxDecoration(
              border: Border.symmetric(
                  horizontal:
                      BorderSide(color: TddColors.border, width: 0.5)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _statCell(
                    label: 'FIABILIDAD',
                    value: '${user.reliabilityScore}',
                  ),
                  const VerticalDivider(
                      width: 0.5, color: TddColors.border),
                  _statCell(
                    label: 'ROL',
                    value: user.role.toUpperCase(),
                  ),
                  const VerticalDivider(
                      width: 0.5, color: TddColors.border),
                  _statCell(
                    label: 'ESTADO',
                    value: user.status == 'active' ? 'Activo' : user.status,
                  ),
                ],
              ),
            ),
          ),
          // Favorites section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'FAVORITOS',
              style: TddTypography.mono(size: 10, color: TddColors.text3),
            ),
          ),
          const Divider(),
          favAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(_favoritesProvider),
            ),
            data: (debates) => debates.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Sin debates favoritos.',
                        style: TddTypography.sans(
                            size: 14, color: TddColors.text3),
                      ),
                    ),
                  )
                : Column(
                    children:
                        debates.map((d) => DebateCard(debate: d)).toList(),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statCell({required String label, required String value}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value,
                style: TddTypography.serif(size: 20, weight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(label,
                style: TddTypography.mono(size: 9, color: TddColors.text3)),
          ],
        ),
      ),
    );
  }
}
