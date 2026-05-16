import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: isOnline ? 0.0 : 32.0,
              color: const Color(0xFF1A1612),
              child: isOnline
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off,
                            size: 13, color: Colors.white60),
                        const SizedBox(width: 7),
                        Text(
                          'Sin conexión a internet',
                          style: TddTypography.mono(
                              size: 10.5, color: Colors.white60),
                        ),
                      ],
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
