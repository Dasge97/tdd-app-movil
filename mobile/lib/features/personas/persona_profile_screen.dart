import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/debate.dart';
import '../../core/models/user.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/debate_card.dart';

final _personaProvider =
    FutureProvider.family<User, String>((ref, username) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.userByUsername(username));
  return User.fromJson(resp.data as Map<String, dynamic>);
});

final _personaDebatesProvider =
    FutureProvider.family<List<Debate>, String>((ref, username) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.personaDebates(username),
      queryParameters: {'page': 1});
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => Debate.fromJson(e as Map<String, dynamic>)).toList();
});

class PersonaProfileScreen extends ConsumerWidget {
  final String username;
  const PersonaProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personaAsync = ref.watch(_personaProvider(username));
    final debatesAsync = ref.watch(_personaDebatesProvider(username));

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
              backgroundColor: TddColors.bg,
              foregroundColor: TddColors.text2,
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: true,
              expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  color: TddColors.bgElev,
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Avatar(
                        username: persona.username,
                        avatarUrl: persona.avatarUrl,
                        size: 72,
                        isAiPersona: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              persona.username,
                              style: TddTypography.serif(
                                  size: 22, weight: FontWeight.w500),
                            ),
                            Text(
                              '@${persona.username}',
                              style: TddTypography.mono(
                                  size: 11, color: TddColors.text3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (persona.personaSpecialty != null)
                      Chip(label: Text(persona.personaSpecialty!)),
                    if (persona.profileTagline != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        persona.profileTagline!,
                        style: TddTypography.serif(
                          size: 16,
                          style: FontStyle.italic,
                          color: TddColors.text2,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (persona.bio != null && persona.bio!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        persona.bio!,
                        style: TddTypography.sans(
                            size: 14, color: TddColors.text2, height: 1.6),
                      ),
                    ],
                    if (persona.profileTraits != null &&
                        persona.profileTraits!.isNotEmpty) ...[
                      const SizedBox(height: 16),
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
                      'DEBATES',
                      style: TddTypography.mono(
                          size: 10, color: TddColors.text3),
                    ),
                    const SizedBox(height: 4),
                    const Divider(),
                  ],
                ),
              ),
            ),
            debatesAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: LoadingIndicator()),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(_personaDebatesProvider(username)),
                ),
              ),
              data: (debates) => debates.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Sin debates publicados.',
                            style: TddTypography.sans(
                                size: 14, color: TddColors.text3),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => DebateCard(debate: debates[i]),
                        childCount: debates.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
