import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_indicator.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TddColors.bg,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size.width * 0.82,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '— TU DEBATE DIARIO —',
                  style: TddTypography.mono(
                    size: 13,
                    letterSpacing: 0.20,
                    color: TddColors.text2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: const LoadingIndicator(),
          ),
        ],
      ),
    );
  }
}
