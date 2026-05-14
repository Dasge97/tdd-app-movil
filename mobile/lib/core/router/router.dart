import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/debate/debate_detail_screen.dart';
import '../../features/debate/propose_debate_screen.dart';
import '../../features/personas/persona_profile_screen.dart';
import '../../features/personas/personas_list_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/social/friends_screen.dart';
import '../../features/chat/conversations_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/profile/my_profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';

final _authRoutes = {'/login', '/register'};

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.user != null;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(location);

      // Still initializing — keep on auth screens, redirect home→login to avoid 401
      if (isLoading) return isAuthRoute ? null : '/login';

      // Not authenticated and not on auth screen → redirect to login
      if (!isAuth && !isAuthRoute) return '/login';

      // Authenticated and on auth screen → redirect to home
      if (isAuth && isAuthRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'debate/:id',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DebateDetailScreen(debateId: id);
            },
          ),
          GoRoute(
            path: 'propose',
            builder: (_, __) => const ProposeDebateScreen(),
          ),
          GoRoute(
            path: 'persona/:username',
            builder: (_, state) {
              final username = state.pathParameters['username']!;
              return PersonaProfileScreen(username: username);
            },
          ),
          GoRoute(
            path: 'personas',
            builder: (_, __) => const PersonasListScreen(),
          ),
          GoRoute(
            path: 'search',
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'friends',
            builder: (_, __) => const FriendsScreen(),
          ),
          GoRoute(
            path: 'conversations',
            builder: (_, __) => const ConversationsScreen(),
          ),
          GoRoute(
            path: 'chat/:conversationId',
            builder: (_, state) {
              final id = int.parse(
                  state.pathParameters['conversationId']!);
              return ChatScreen(conversationId: id);
            },
          ),
          GoRoute(
            path: 'profile',
            builder: (_, __) => const MyProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, __) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
