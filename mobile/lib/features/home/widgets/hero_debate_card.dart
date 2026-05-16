import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/debate.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/avatar.dart';

class HeroDebateCard extends StatelessWidget {
  final Debate debate;

  const HeroDebateCard({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    final user = debate.createdBy;
    final ago = debate.publishedAt != null
        ? timeago.format(debate.publishedAt!, locale: 'es')
        : '';

    return InkWell(
      onTap: () => context.push('/home/debate/${debate.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: TddColors.bgElev,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TddColors.borderStrong, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // cabecera: persona + tiempo + badge "#1 semana"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Avatar(
                    username: user.username,
                    avatarUrl: user.avatarUrl,
                    size: 30,
                    isAiPersona: user.isAiPersona,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.username,
                      style: TddTypography.sans(
                          size: 13, weight: FontWeight.w500),
                    ),
                  ),
                  if (ago.isNotEmpty)
                    Text(ago,
                        style:
                            TddTypography.mono(size: 9.5, color: TddColors.text4)),
                ],
              ),
            ),
            // badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TddColors.accentSoft,
                  borderRadius: BorderRadius.circular(3),
                  border:
                      Border.all(color: TddColors.accentRing, width: 0.5),
                ),
                child: Text(
                  '#1 DE LA SEMANA',
                  style: TddTypography.mono(
                    size: 8.5,
                    letterSpacing: 0.2,
                    color: TddColors.accent,
                  ),
                ),
              ),
            ),
            // título
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                debate.title,
                style: TddTypography.serif(
                  size: 22,
                  weight: FontWeight.w500,
                  letterSpacing: -0.02,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // resumen
            if (debate.cardSummary != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  debate.cardSummary!,
                  style: TddTypography.sans(
                      size: 14, color: TddColors.text3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 13, color: TddColors.text3),
                  const SizedBox(width: 5),
                  Text(
                    '${debate.commentCount ?? 0} comentarios',
                    style:
                        TddTypography.mono(size: 10, color: TddColors.text3),
                  ),
                  const Spacer(),
                  Text(
                    'Leer debate →',
                    style: TddTypography.mono(
                        size: 9.5, color: TddColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
