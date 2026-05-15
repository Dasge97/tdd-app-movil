import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/friend.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _friendsProvider = FutureProvider<List<Friend>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.friends);
  final Map<String, dynamic> data = resp.data as Map<String, dynamic>;
  final list = [
    ...(data['friends'] as List? ?? []),
    ...(data['pending'] as List? ?? []),
  ];
  return list
      .map((e) => Friend.fromJson(e as Map<String, dynamic>))
      .toList();
});

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(String username) async {
    try {
      final dio = ref.read(apiClientProvider);
      // Backend exposes POST /api/v1/friends with { "username": "..." }
      await dio.post(ApiEndpoints.friends,
          data: {'username': username});
      ref.invalidate(_friendsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Solicitud de amistad enviada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _openConversationWith(int otherUserId) async {
    try {
      final dio = ref.read(apiClientProvider);
      // Find or create the DM conversation, then navigate.
      final resp = await dio.post('/api/v1/chat/conversations',
          data: {'userId': otherUserId});
      final convId = (resp.data as Map<String, dynamic>)['id'] as int;
      if (mounted) context.push('/home/chat/$convId');
    } catch (e) {
      // Fallback: open the list if direct DM lookup isn't available
      if (mounted) context.push('/home/conversations');
    }
  }

  Future<void> _acceptRequest(int userId) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.put(ApiEndpoints.friendAccept(userId));
      ref.invalidate(_friendsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _rejectRequest(int userId) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.delete(ApiEndpoints.friendById(userId));
      ref.invalidate(_friendsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showAddFriend() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar amigo'),
        content: TextField(
          controller: ctrl,
          decoration:
              const InputDecoration(labelText: 'Nombre de usuario'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) {
                _sendRequest(ctrl.text.trim());
              }
            },
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_friendsProvider);
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amigos'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Amigos'),
            Tab(text: 'Solicitudes'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriend,
        tooltip: 'Agregar amigo',
        child: const Icon(Icons.person_add_outlined),
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_friendsProvider),
        ),
        data: (friends) {
          final accepted = friends
              .where((f) => f.status == 'accepted')
              .toList();
          final pending = friends
              .where((f) =>
                  f.status == 'pending' &&
                  f.addressee.id == me?.id)
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              // Friends tab
              accepted.isEmpty
                  ? const Center(
                      child: Text('Aún no tienes amigos'))
                  : ListView.builder(
                      itemCount: accepted.length,
                      itemBuilder: (_, i) {
                        final f = accepted[i];
                        final other = f.requester.id == me?.id
                            ? f.addressee
                            : f.requester;
                        return ListTile(
                          leading: Avatar(
                            username: other.username,
                            avatarUrl: other.avatarUrl,
                          ),
                          title: Text(other.username),
                          subtitle: other.bio != null
                              ? Text(other.bio!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          onTap: () => _openConversationWith(other.id),
                        );
                      },
                    ),
              // Pending tab
              pending.isEmpty
                  ? const Center(
                      child: Text('Sin solicitudes pendientes'))
                  : ListView.builder(
                      itemCount: pending.length,
                      itemBuilder: (_, i) {
                        final f = pending[i];
                        return ListTile(
                          leading: Avatar(
                            username: f.requester.username,
                            avatarUrl: f.requester.avatarUrl,
                          ),
                          title: Text(f.requester.username),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.greenAccent),
                                onPressed: () =>
                                    _acceptRequest(f.requester.id),
                                tooltip: 'Aceptar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    _rejectRequest(f.requester.id),
                                tooltip: 'Rechazar',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}
