import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/user.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _personasProvider = FutureProvider<List<User>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.personas);
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
});

class PersonasListScreen extends ConsumerWidget {
  const PersonasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_personasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: TddColors.text2),
        title:
            Text('Perfiles IA', style: TddTypography.serif(size: 17, weight: FontWeight.w500)),
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_personasProvider),
        ),
        data: (personas) => ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: personas.length,
          itemBuilder: (_, i) => _PersonaRow(persona: personas[i]),
        ),
      ),
    );
  }
}

class _PersonaRow extends StatelessWidget {
  final User persona;
  const _PersonaRow({required this.persona});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/home/persona/${persona.username}'),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Avatar(
              username: persona.username,
              avatarUrl: persona.avatarUrl,
              size: 48,
              isAiPersona: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        persona.username,
                        style: TddTypography.sans(
                            size: 15, weight: FontWeight.w500),
                      ),
                      if (persona.personaSpecialty != null) ...[
                        const SizedBox(width: 8),
                        Chip(label: Text(persona.personaSpecialty!)),
                      ],
                    ],
                  ),
                  if (persona.profileTagline != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      persona.profileTagline!,
                      style: TddTypography.sans(
                          size: 13,
                          color: TddColors.text3,
                          style: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: TddColors.text4),
          ],
        ),
      ),
    );
  }
}
