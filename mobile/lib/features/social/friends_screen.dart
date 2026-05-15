import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/friend.dart';
import '../../shared/theme/app_theme.dart';
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
  return list.map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList();
});

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0; // 0 = Amigos, 1 = Solicitudes

  Future<void> _sendRequest(String username) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(ApiEndpoints.friends, data: {'username': username});
      ref.invalidate(_friendsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _openDm(int otherUserId) async {
    try {
      final dio = ref.read(apiClientProvider);
      final resp = await dio.post('/api/v1/chat/conversations',
          data: {'userId': otherUserId});
      final convId = (resp.data as Map<String, dynamic>)['id'] as int;
      if (mounted) context.push('/home/chat/$convId');
    } catch (_) {
      if (mounted) context.push('/home/conversations');
    }
  }

  Future<void> _accept(int userId) async {
    try {
      await ref.read(apiClientProvider).put(ApiEndpoints.friendAccept(userId));
      ref.invalidate(_friendsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _reject(int userId) async {
    try {
      await ref
          .read(apiClientProvider)
          .delete(ApiEndpoints.friendById(userId));
      ref.invalidate(_friendsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Agregar amigo',
          style: TddTypography.serif(size: 19, weight: FontWeight.w500),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TddTypography.sans(size: 15),
          decoration:
              const InputDecoration(labelText: 'NOMBRE DE USUARIO'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TddTypography.mono(size: 11, color: TddColors.text3)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) {
                _sendRequest(ctrl.text.trim());
              }
            },
            child: const Text('Enviar'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Agregar amigo',
        child: const Icon(Icons.person_add_outlined, size: 22),
      ),
      body: Column(
        children: [
          // Segmented tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: TddColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                _seg(0, 'Amigos'),
                _seg(1, 'Solicitudes'),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(_friendsProvider),
              ),
              data: (friends) {
                final accepted =
                    friends.where((f) => f.status == 'accepted').toList();
                final pending = friends
                    .where((f) =>
                        f.status == 'pending' && f.addressee.id == me?.id)
                    .toList();

                if (_tab == 0) {
                  return accepted.isEmpty
                      ? Center(
                          child: Text(
                            'Aún no tienes amigos.',
                            style: TddTypography.sans(
                                size: 14, color: TddColors.text3),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: accepted.length,
                          itemBuilder: (_, i) {
                            final f = accepted[i];
                            final other = f.requester.id == me?.id
                                ? f.addressee
                                : f.requester;
                            return _FriendRow(
                              name: other.username,
                              bio: other.bio,
                              avatarUrl: other.avatarUrl,
                              onTap: () => _openDm(other.id),
                            );
                          },
                        );
                } else {
                  return pending.isEmpty
                      ? Center(
                          child: Text(
                            'Sin solicitudes pendientes.',
                            style: TddTypography.sans(
                                size: 14, color: TddColors.text3),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: pending.length,
                          itemBuilder: (_, i) {
                            final f = pending[i];
                            return _RequestRow(
                              name: f.requester.username,
                              avatarUrl: f.requester.avatarUrl,
                              onAccept: () => _accept(f.requester.id),
                              onReject: () => _reject(f.requester.id),
                            );
                          },
                        );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? TddColors.text : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TddTypography.mono(
              size: 11,
              color: selected ? TddColors.text : TddColors.text3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rows ──────────────────────────────────────────────────────────────────────

class _FriendRow extends StatelessWidget {
  final String name;
  final String? bio;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _FriendRow({
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Avatar(username: name, avatarUrl: avatarUrl, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          TddTypography.sans(size: 14, weight: FontWeight.w500)),
                  if (bio != null && bio!.isNotEmpty)
                    Text(
                      bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TddTypography.sans(size: 13, color: TddColors.text3),
                    ),
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

class _RequestRow extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestRow({
    required this.name,
    this.avatarUrl,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Avatar(username: name, avatarUrl: avatarUrl, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name,
                style: TddTypography.sans(size: 14, weight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: onReject,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: TddColors.border, width: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: TddColors.text3),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAccept,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: TddColors.favor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
