import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/debate.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/debate_card.dart';

final _favoritesProvider =
    FutureProvider<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.myFavorites);
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => Debate.fromJson(e as Map<String, dynamic>))
      .toList();
});

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final favAsync = ref.watch(_favoritesProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/home/profile/edit'),
            tooltip: 'Editar perfil',
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Avatar(
              username: user.username,
              avatarUrl: user.avatarUrl,
              radius: 48,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '@${user.username}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (user.profileTagline != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                user.profileTagline!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white54),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_outline,
                    color: Color(0xFF4FC3F7), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Fiabilidad: ${user.reliabilityScore}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (user.location != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(user.location!,
                      style:
                          Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
              onPressed: () =>
                  context.push('/home/profile/edit'),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Favoritos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          favAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(_favoritesProvider),
            ),
            data: (debates) => debates.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('Sin debates favoritos')),
                  )
                : Column(
                    children: debates
                        .map((d) => DebateCard(debate: d))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
