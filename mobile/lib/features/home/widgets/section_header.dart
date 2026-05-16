import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TddColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TddTypography.mono(
              size: 10,
              letterSpacing: 0.18,
              color: TddColors.text3,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
