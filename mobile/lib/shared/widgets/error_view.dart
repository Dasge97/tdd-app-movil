import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '—',
              style: TddTypography.serif(size: 32, color: TddColors.text4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TddTypography.sans(size: 14, color: TddColors.text3),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Reintentar',
                  style: TddTypography.mono(size: 11, color: TddColors.text3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
