import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/ticker_widget.dart';
import '../chat/conversations_screen.dart';
import '../profile/my_profile_screen.dart';
import '../social/friends_screen.dart';
import 'home_providers.dart';
import 'tabs/hoy_tab.dart';
import 'tabs/protagonistas_tab.dart';
import 'tabs/semana_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0=Proponer(CTA), 1=Amigos, 2=Inicio, 3=Mensajes, 4=Perfil
  int _navIndex = 2;

  static const _sideScreens = <Widget>[
    FriendsScreen(),
    ConversationsScreen(),
    MyProfileScreen(),
  ];

  // navIndex 1→0, 3→1, 4→2
  int get _sideIndex => switch (_navIndex) {
        1 => 0,
        3 => 1,
        4 => 2,
        _ => 0,
      };

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
      body: _navIndex == 2
          ? const _InicioPanel()
          : IndexedStack(index: _sideIndex, children: _sideScreens),
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
          title: Image.asset('assets/images/logo.png', height: 36),
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
                child: const Icon(Icons.add,
                    color: TddColors.accentInk, size: 20),
              )
            else
              Icon(icon,
                  size: 22,
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

// ── Panel Inicio: ticker + subtabs HOY | SEMANA | PROTAGONISTAS ──────────────

class _InicioPanel extends ConsumerStatefulWidget {
  const _InicioPanel();

  @override
  ConsumerState<_InicioPanel> createState() => _InicioPanelState();
}

class _InicioPanelState extends ConsumerState<_InicioPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickerAsync = ref.watch(tickerDebatesProvider);

    return Column(
      children: [
        // ticker auto-scroll
        tickerAsync.when(
          loading: () => const SizedBox(height: 34),
          error: (_, _) => const SizedBox.shrink(),
          data: (debates) => debates.isNotEmpty
              ? TickerWidget(debates: debates)
              : const SizedBox.shrink(),
        ),

        // barra de subtabs
        Container(
          color: TddColors.bg,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: TddColors.accent,
            indicatorWeight: 1.5,
            dividerColor: TddColors.border,
            dividerHeight: 0.5,
            labelStyle: TddTypography.mono(
                size: 10.5, color: TddColors.text, letterSpacing: 0.15),
            unselectedLabelStyle: TddTypography.mono(
                size: 10.5, color: TddColors.text3, letterSpacing: 0.15),
            tabs: const [
              Tab(text: 'HOY'),
              Tab(text: 'SEMANA'),
              Tab(text: 'PROTAGONISTAS'),
            ],
          ),
        ),

        // contenido de cada tab
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              HoyTab(),
              SemanaTab(),
              ProtagonistaTab(),
            ],
          ),
        ),
      ],
    );
  }
}
