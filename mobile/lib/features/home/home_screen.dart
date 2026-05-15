import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/debate.dart';
import '../../core/models/user.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../chat/conversations_screen.dart';
import '../profile/my_profile_screen.dart';
import '../social/friends_screen.dart';
import 'debate_card.dart';

final _todayDebatesProvider =
    FutureProvider.autoDispose<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debatesToday);
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list.map((e) => Debate.fromJson(e as Map<String, dynamic>)).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0=Proponer(CTA), 1=Amigos, 2=Inicio, 3=Mensajes, 4=Perfil
  int _navIndex = 2;

  static const _tabs = <Widget>[
    FriendsScreen(),
    _DebateFeedTab(),
    ConversationsScreen(),
    MyProfileScreen(),
  ];

  // Nav 1→tab 0, nav 2→tab 1, nav 3→tab 2, nav 4→tab 3
  int get _tabIndex => _navIndex - 1;

  void _onTap(int index) {
    if (index == 0) {
      context.push('/home/propose');
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: _buildAppBar(user),
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: _buildNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(User? user) {
    switch (_navIndex) {
      case 1:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text('Amigos',
              style: TddTypography.serif(size: 17, weight: FontWeight.w500)),
        );
      case 3:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text('Mensajes',
              style: TddTypography.serif(size: 17, weight: FontWeight.w500)),
        );
      case 4:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: user != null
              ? Text('@${user.username}',
                  style: TddTypography.mono(size: 12, color: TddColors.text3))
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              color: TddColors.text2,
              onPressed: () => context.push('/home/profile/settings'),
            ),
          ],
        );
      default: // case 2 = Inicio
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Image.asset('assets/images/logo_nombre.png', height: 22),
          leading: IconButton(
            icon: const Icon(Icons.search, size: 22),
            color: TddColors.text2,
            onPressed: () => context.push('/home/search'),
            tooltip: 'Buscar',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined, size: 22),
              color: TddColors.text2,
              onPressed: () => context.push('/home/personas'),
              tooltip: 'Perfiles IA',
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              color: TddColors.text2,
              onPressed: () => context.push('/home/notifications'),
              tooltip: 'Notificaciones',
            ),
          ],
        );
    }
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: TddColors.bg,
        border: Border(top: BorderSide(color: TddColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _navItem(0, Icons.add, 'Proponer', isCta: true),
              _navItem(1, Icons.people_outline, 'Amigos'),
              _navItem(2, Icons.home_outlined, 'Inicio'),
              _navItem(3, Icons.chat_bubble_outline, 'Mensajes'),
              _navItem(4, Icons.person_outline, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      {bool isCta = false}) {
    final selected = _navIndex == index && !isCta;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCta)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: TddColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: TddColors.accentInk, size: 20),
              )
            else
              Icon(icon, size: 22,
                  color: selected ? TddColors.text : TddColors.text3),
            const SizedBox(height: 2),
            Text(
              label,
              style: TddTypography.mono(
                size: 9,
                color: isCta
                    ? TddColors.accent
                    : (selected ? TddColors.text : TddColors.text3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feed tab ──────────────────────────────────────────────────────────────────

class _DebateFeedTab extends ConsumerStatefulWidget {
  const _DebateFeedTab();

  @override
  ConsumerState<_DebateFeedTab> createState() => _DebateFeedTabState();
}

class _DebateFeedTabState extends ConsumerState<_DebateFeedTab> {
  Future<void> _refresh() async {
    ref.invalidate(_todayDebatesProvider);
    await ref.read(_todayDebatesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_todayDebatesProvider);

    return async.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_todayDebatesProvider),
      ),
      data: (debates) => RefreshIndicator(
        color: TddColors.accent,
        onRefresh: _refresh,
        child: debates.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Sin debates hoy.\nVuelve pronto.',
                      textAlign: TextAlign.center,
                      style: TddTypography.sans(
                          size: 15, color: TddColors.text3),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: debates.length,
                itemBuilder: (_, i) => DebateCard(debate: debates[i]),
              ),
      ),
    );
  }
}
