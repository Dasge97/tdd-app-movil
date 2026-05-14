import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/debate.dart';
import '../../core/models/user.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/debate_card.dart';

final _personaProvider =
    FutureProvider.family<User, String>((ref, username) async {
  final dio = ref.read(apiClientProvider);
  final resp =
      await dio.get(ApiEndpoints.userByUsername(username));
  return User.fromJson(resp.data as Map<String, dynamic>);
});

final _personaDebatesProvider =
    FutureProvider.family<List<Debate>, String>(
        (ref, username) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(
    ApiEndpoints.personaDebates(username),
    queryParameters: {'page': 1},
  );
  final list = (resp.data['data'] as List? ?? resp.data as List);
  return list
      .map((e) => Debate.fromJson(e as Map<String, dynamic>))
      .toList();
});

class PersonaProfileScreen extends ConsumerWidget {
  final String username;

  const PersonaProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personaAsync = ref.watch(_personaProvider(username));
    final debatesAsync =
        ref.watch(_personaDebatesProvider(username));

    return Scaffold(
      body: personaAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_personaProvider(username)),
        ),
        data: (persona) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('@${persona.username}'),
                background: Container(
                  color: const Color(0xFF1A1A2E),
                  child: Center(
                    child: Avatar(
                      username: persona.username,
                      avatarUrl: persona.avatarUrl,
                      radius: 56,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (persona.personaSpecialty != null)
                      Chip(
                          label:
                              Text(persona.personaSpecialty!)),
                    if (persona.profileTagline != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        persona.profileTagline!,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.white70),
                      ),
                    ],
                    if (persona.bio != null &&
                        persona.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        persona.bio!,
                        style:
                            Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (persona.profileTraits != null &&
                        persona.profileTraits!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Rasgos',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: persona.profileTraits!
                            .map((t) => Chip(label: Text(t)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Debates',
                      style:
                          Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            debatesAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: LoadingIndicator()),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(
                      _personaDebatesProvider(username)),
                ),
              ),
              data: (debates) => debates.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child:
                                Text('Sin debates publicados')),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => DebateCard(debate: debates[i]),
                        childCount: debates.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
