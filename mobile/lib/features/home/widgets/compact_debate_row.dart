import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/debate.dart';
import '../../../shared/theme/app_theme.dart';

class CompactDebateRow extends StatelessWidget {
  final Debate debate;
  final int? rank;

  const CompactDebateRow({super.key, required this.debate, this.rank});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/home/debate/${debate.id}'),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 28,
                child: Text(
                  '$rank',
                  style: TddTypography.mono(
                    size: 13,
                    color: rank! <= 3 ? TddColors.accent : TddColors.text4,
                  ),
                ),
              ),
            ],
            Expanded(
              child: Text(
                debate.title,
                style: TddTypography.serif(
                  size: 15,
                  weight: FontWeight.w500,
                  letterSpacing: -0.01,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${debate.commentCount ?? 0}',
                  style: TddTypography.mono(size: 12, color: TddColors.text2),
                ),
                Text(
                  'comments',
                  style: TddTypography.mono(size: 9, color: TddColors.text4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
