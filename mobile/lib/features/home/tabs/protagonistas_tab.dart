import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../home_providers.dart';

class ProtagonistaTab extends ConsumerStatefulWidget {
  const ProtagonistaTab({super.key});

  @override
  ConsumerState<ProtagonistaTab> createState() => _ProtagonistaTabState();
}

class _ProtagonistaTabState extends ConsumerState<ProtagonistaTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final async = ref.watch(protagonistasProvider);

    return RefreshIndicator(
      color: TddColors.accent,
      onRefresh: () async => ref.invalidate(protagonistasProvider),
      child: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(protagonistasProvider),
        ),
        data: (users) => _buildList(users),
      ),
    );
  }

  Widget _buildList(List<User> users) {
    if (users.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Aún no hay protagonistas.',
              style: TddTypography.sans(size: 15, color: TddColors.text3),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: users.length + 1, // +1 para el header informativo
      itemBuilder: (context, i) {
        if (i == 0) return _buildListHeader();
        return _ProtagonistaRow(user: users[i - 1], rank: i);
      },
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTAGONISTAS',
            style: TddTypography.mono(
              size: 10,
              letterSpacing: 0.18,
              color: TddColors.text3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Los usuarios con mayor puntuación de fiabilidad.',
            style: TddTypography.sans(size: 13, color: TddColors.text3),
          ),
          const SizedBox(height: 12),
          const Divider(height: 0.5, thickness: 0.5, color: TddColors.border),
        ],
      ),
    );
  }
}

// ── Fila de protagonista ─────────────────────────────────────────────────────

class _ProtagonistaRow extends StatelessWidget {
  final User user;
  final int rank;

  const _ProtagonistaRow({required this.user, required this.rank});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/home/profile/${user.username}'),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // posición
            SizedBox(
              width: 32,
              child: _rankWidget(rank),
            ),
            // avatar
            Avatar(
              username: user.username,
              avatarUrl: user.avatarUrl,
              size: 36,
            ),
            const SizedBox(width: 12),
            // info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.username}',
                    style: TddTypography.sans(
                        size: 14, weight: FontWeight.w500),
                  ),
                  if (user.profileTagline != null &&
                      user.profileTagline!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.profileTagline!,
                      style: TddTypography.sans(
                          size: 12, color: TddColors.text3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.reliabilityScore}',
                  style: TddTypography.mono(
                    size: 15,
                    color: rank <= 3 ? TddColors.accent : TddColors.text2,
                  ),
                ),
                Text(
                  'pts',
                  style:
                      TddTypography.mono(size: 9, color: TddColors.text4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankWidget(int r) {
    if (r == 1) {
      return const Text('🥇',
          style: TextStyle(fontSize: 18), textAlign: TextAlign.center);
    }
    if (r == 2) {
      return const Text('🥈',
          style: TextStyle(fontSize: 18), textAlign: TextAlign.center);
    }
    if (r == 3) {
      return const Text('🥉',
          style: TextStyle(fontSize: 18), textAlign: TextAlign.center);
    }
    return Text(
      '$r',
      style: TddTypography.mono(size: 12, color: TddColors.text4),
      textAlign: TextAlign.center,
    );
  }
}
