import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/notification.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';

final _notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final resp = await dio.get(ApiEndpoints.notifications);
  final List list = resp.data is List
      ? resp.data as List
      : ((resp.data as Map<String, dynamic>)['data'] as List? ?? []);
  return list
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
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
        return Icons.arrow_upward;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _markRead(WidgetRef ref, int id) async {
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
        leading: BackButton(color: TddColors.text2),
        title: Text(
          'Notificaciones',
          style: TddTypography.serif(size: 17, weight: FontWeight.w500),
        ),
        actions: [
          GestureDetector(
            onTap: () => _markAllRead(ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Todo leído',
                style: TddTypography.mono(size: 10, color: TddColors.text3),
              ),
            ),
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
            ? Center(
                child: Text(
                  'Sin notificaciones.',
                  style: TddTypography.sans(size: 14, color: TddColors.text3),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  return GestureDetector(
                    onTap: () => n.isRead ? null : _markRead(ref, n.id),
                    child: Container(
                      color: n.isRead ? null : TddColors.unread,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: TddColors.border, width: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? TddColors.surface2
                                  : TddColors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForType(n.type),
                              size: 18,
                              color: n.isRead
                                  ? TddColors.text3
                                  : TddColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TddTypography.sans(
                                    size: 14,
                                    weight: n.isRead
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  n.body,
                                  style: TddTypography.sans(
                                      size: 13, color: TddColors.text3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(n.createdAt, locale: 'es'),
                                  style: TddTypography.mono(
                                      size: 10, color: TddColors.text4),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: const BoxDecoration(
                                color: TddColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
