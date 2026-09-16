import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/brand.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass_background.dart';

class MokojiApp extends ConsumerWidget {
  const MokojiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: Brand.name,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: GlassBackground(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
