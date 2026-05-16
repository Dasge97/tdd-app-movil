import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/debate.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../home_providers.dart';
import '../widgets/compact_debate_row.dart';
import '../widgets/hero_debate_card.dart';
import '../widgets/section_header.dart';

class SemanaTab extends ConsumerStatefulWidget {
  const SemanaTab({super.key});

  @override
  ConsumerState<SemanaTab> createState() => _SemanaTabState();
}

class _SemanaTabState extends ConsumerState<SemanaTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final async = ref.watch(topWeekProvider);

    return RefreshIndicator(
      color: TddColors.accent,
      onRefresh: () async => ref.invalidate(topWeekProvider),
      child: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(topWeekProvider),
        ),
        data: (debates) => _buildContent(debates),
      ),
    );
  }

  Widget _buildContent(List<Debate> debates) {
    if (debates.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Sin datos esta semana.',
              style: TddTypography.sans(size: 15, color: TddColors.text3),
            ),
          ),
        ],
      );
    }

    final hero = debates.first;
    final rest = debates.skip(1).toList();

    return CustomScrollView(
      slivers: [
        // HeroCard: #1 de la semana
        SliverToBoxAdapter(child: HeroDebateCard(debate: hero)),

        // Top de la semana (posiciones 2+)
        if (rest.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'TOP DE LA SEMANA'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => CompactDebateRow(debate: rest[i], rank: i + 2),
              childCount: rest.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
