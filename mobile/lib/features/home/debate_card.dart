import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/models/debate.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/home/debate/${debate.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(
                    username: user.username,
                    avatarUrl: user.avatarUrl,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.username,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600),
                            ),
                            if (user.isAiPersona &&
                                user.personaSpecialty != null) ...[
                              const SizedBox(width: 6),
                              Chip(
                                label:
                                    Text(user.personaSpecialty!),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize
                                        .shrinkWrap,
                              ),
                            ],
                          ],
                        ),
                        if (publishedAgo.isNotEmpty)
                          Text(
                            publishedAgo,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                debate.title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (debate.cardSummary != null) ...[
                const SizedBox(height: 6),
                Text(
                  debate.cardSummary!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.comment_outlined,
                      size: 16, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    '${debate.commentCount ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
