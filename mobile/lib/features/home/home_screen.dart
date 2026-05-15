import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/debate.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../chat/conversations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/my_profile_screen.dart';
import '../search/search_screen.dart';
import '../social/friends_screen.dart';
import 'debate_card.dart';

final _todayDebatesProvider =
    FutureProvider.autoDispose<List<Debate>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.debatesToday);
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => Debate.fromJson(e as Map<String, dynamic>))
      .toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _DebateFeedTab(),
    SearchScreen(),
    ConversationsScreen(),
    NotificationsScreen(),
    FriendsScreen(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text(
                'TDD',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 3,
                    color: Color(0xFF4FC3F7)),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.smart_toy_outlined),
                  tooltip: 'Perfiles IA',
                  onPressed: () =>
                      context.push('/home/personas'),
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Amigos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _DebateFeedTab extends ConsumerStatefulWidget {
  const _DebateFeedTab();

  @override
  ConsumerState<_DebateFeedTab> createState() =>
      _DebateFeedTabState();
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
        onRefresh: _refresh,
        child: debates.isEmpty
            ? const Center(
                child: Text('Sin debates hoy. ¡Vuelve pronto!'),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: debates.length,
                itemBuilder: (_, i) =>
                    DebateCard(debate: debates[i]),
              ),
      ),
    );
  }
}
