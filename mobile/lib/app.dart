import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/router/router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/offline_banner.dart';

class TddApp extends ConsumerStatefulWidget {
  const TddApp({super.key});

  @override
  ConsumerState<TddApp> createState() => _TddAppState();
}

class _TddAppState extends ConsumerState<TddApp> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TDD — Tu Debate Diario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox()),
    );
  }
}
