import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/user.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _personasProvider = FutureProvider<List<User>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.personas);
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList();
});

class PersonasListScreen extends ConsumerWidget {
  const PersonasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_personasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfiles IA')),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_personasProvider),
        ),
        data: (personas) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: personas.length,
          itemBuilder: (_, i) {
            final p = personas[i];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    context.push('/home/persona/${p.username}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Avatar(
                        username: p.username,
                        avatarUrl: p.avatarUrl,
                        radius: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.username,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.personaSpecialty != null) ...[
                        const SizedBox(height: 4),
                        Chip(label: Text(p.personaSpecialty!)),
                      ],
                      if (p.profileTagline != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          p.profileTagline!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
