import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/debate.dart';
import '../../../core/models/user.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../debate_card.dart';
import '../home_providers.dart';
import '../widgets/compact_debate_row.dart';
import '../widgets/section_header.dart';

class HoyTab extends ConsumerStatefulWidget {
  const HoyTab({super.key});

  @override
  ConsumerState<HoyTab> createState() => _HoyTabState();
}

class _HoyTabState extends ConsumerState<HoyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    ref.invalidate(todayDebatesProvider);
    ref.invalidate(topTodayProvider);
    ref.invalidate(recentDebatesProvider);
    ref.invalidate(aiPersonasProvider);
    ref.read(selectedPersonaFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final todayAsync = ref.watch(todayDebatesProvider);
    final topAsync = ref.watch(topTodayProvider);
    final selectedPersona = ref.watch(selectedPersonaFilterProvider);
    final recentAsync = ref.watch(recentDebatesProvider(selectedPersona));
    final personasAsync = ref.watch(aiPersonasProvider);

    return RefreshIndicator(
      color: TddColors.accent,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          // ── Sección 1: Los 5 de hoy ──────────────────────────────────────
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'LOS 5 DE HOY'),
          ),
          _buildTodaySection(todayAsync),

          // ── Sección 2: Más interacción hoy ───────────────────────────────
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'MÁS INTERACCIÓN HOY'),
          ),
          _buildTopTodaySection(topAsync),

          // ── Sección 3: Recientes ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'RECIENTES',
              trailing: personasAsync.maybeWhen(
                data: (personas) => _PersonaFilterRow(
                  personas: personas,
                  selected: selectedPersona,
                  onSelect: (u) => ref
                      .read(selectedPersonaFilterProvider.notifier)
                      .state = u,
                ),
                orElse: () => null,
              ),
            ),
          ),
          // chips de filtro (barra horizontal independiente)
          personasAsync.maybeWhen(
            data: (personas) => SliverToBoxAdapter(
              child: _PersonaChipsBar(
                personas: personas,
                selected: selectedPersona,
                onSelect: (u) => ref
                    .read(selectedPersonaFilterProvider.notifier)
                    .state = u,
              ),
            ),
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          _buildRecentSection(recentAsync),

          // padding inferior
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildTodaySection(AsyncValue<List<Debate>> async) {
    return async.when(
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(todayDebatesProvider),
        ),
      ),
      data: (debates) {
        if (debates.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sin debates hoy. Vuelve pronto.',
                style: TddTypography.sans(size: 14, color: TddColors.text3),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final limited = debates.take(5).toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => DebateCard(debate: limited[i]),
            childCount: limited.length,
          ),
        );
      },
    );
  }

  Widget _buildTopTodaySection(AsyncValue<List<Debate>> async) {
    return async.when(
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (_, _) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (debates) {
        if (debates.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox(height: 8));
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => CompactDebateRow(debate: debates[i], rank: i + 1),
            childCount: debates.length,
          ),
        );
      },
    );
  }

  Widget _buildRecentSection(AsyncValue<List<Debate>> async) {
    return async.when(
      loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            recentDebatesProvider(ref.read(selectedPersonaFilterProvider)),
          ),
        ),
      ),
      data: (debates) {
        if (debates.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sin debates recientes.',
                style: TddTypography.sans(size: 14, color: TddColors.text3),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => CompactDebateRow(debate: debates[i]),
            childCount: debates.length,
          ),
        );
      },
    );
  }
}

// ── Barra de chips de filtro por persona ────────────────────────────────────

class _PersonaChipsBar extends StatelessWidget {
  final List<User> personas;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _PersonaChipsBar({
    required this.personas,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip('Todos', null),
          ...personas.map((p) => _chip(p.username, p.username)),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onSelect(isSelected ? null : value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? TddColors.accent : TddColors.accentSoft,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isSelected ? TddColors.accent : TddColors.accentRing,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TddTypography.mono(
              size: 9.5,
              color: isSelected ? TddColors.accentInk : TddColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

// stub vacío para trailing en SectionHeader (no se usa actualmente)
class _PersonaFilterRow extends StatelessWidget {
  final List<User> personas;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _PersonaFilterRow({
    required this.personas,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
