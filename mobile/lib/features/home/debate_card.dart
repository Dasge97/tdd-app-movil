import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/models/debate.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/avatar.dart';

class DebateCard extends StatelessWidget {
  final Debate debate;

  const DebateCard({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    final user = debate.createdBy;
    final publishedAgo = debate.publishedAt != null
        ? timeago.format(debate.publishedAt!, locale: 'es')
        : '';

    return InkWell(
      onTap: () => context.push('/home/debate/${debate.id}'),
      child: Container(
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  size: 28,
                  isAiPersona: user.isAiPersona,
                ),
                const SizedBox(width: 8),
                Text(
                  user.username,
                  style: TddTypography.sans(size: 13, weight: FontWeight.w500),
                ),
                if (user.isAiPersona && user.personaSpecialty != null) ...[
                  const SizedBox(width: 6),
                  Chip(label: Text(user.personaSpecialty!)),
                ],
                const Spacer(),
                if (publishedAgo.isNotEmpty)
                  Text(
                    publishedAgo,
                    style: TddTypography.mono(size: 10, color: TddColors.text4),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              debate.title,
              style: TddTypography.serif(
                size: 19,
                weight: FontWeight.w500,
                letterSpacing: -0.015,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (debate.cardSummary != null) ...[
              const SizedBox(height: 5),
              Text(
                debate.cardSummary!,
                style: TddTypography.sans(size: 14, color: TddColors.text3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              '${debate.commentCount ?? 0} comentarios',
              style: TddTypography.mono(size: 10, color: TddColors.text3),
            ),
          ],
        ),
      ),
    );
  }
}
