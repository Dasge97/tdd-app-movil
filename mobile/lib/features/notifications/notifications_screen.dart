import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/notification.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.notifications);
  final List list = resp.data is List ? resp.data as List : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) =>
          AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add_outlined;
      case 'friend_accepted':
        return Icons.people_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'vote':
        return Icons.thumb_up_outlined;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _markRead(
      WidgetRef ref, int id) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.put(ApiEndpoints.notificationRead(id));
      ref.invalidate(_notificationsProvider);
    } catch (_) {}
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.put(ApiEndpoints.notificationsReadAll);
      ref.invalidate(_notificationsProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: const Text('Marcar todo leído',
                style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_notificationsProvider),
        ),
        data: (notifications) => notifications.isEmpty
            ? const Center(child: Text('Sin notificaciones'))
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  return ListTile(
                    tileColor: n.isRead
                        ? null
                        : const Color(0xFF1E2D50).withOpacity(0.5),
                    leading: Icon(
                      _iconForType(n.type),
                      color: n.isRead
                          ? Colors.white38
                          : const Color(0xFF4FC3F7),
                    ),
                    title: Text(n.title,
                        style: TextStyle(
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.body),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(n.createdAt,
                              locale: 'es'),
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () =>
                        n.isRead ? null : _markRead(ref, n.id),
                  );
                },
              ),
      ),
    );
  }
}
