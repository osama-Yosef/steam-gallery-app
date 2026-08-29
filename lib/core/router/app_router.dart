import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/role_home_screen.dart';
import '../config/env.dart';
import '../screens/config_missing_screen.dart';
import '../supabase/supabase_client_provider.dart';
import 'go_router_refresh_stream.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Must be checked BEFORE touching supabaseClientProvider at all: without
  // --dart-define values, Supabase.initialize() was never called in main(),
  // so Supabase.instance.client throws. This is the only router the app
  // builds until real credentials are supplied (Module 0 bootstrap).
  if (!Env.isConfigured) {
    return GoRouter(
      initialLocation: Routes.configMissing,
      routes: [GoRoute(path: Routes.configMissing, builder: (_, _) => const ConfigMissingScreen())],
    );
  }

  final refreshStream = GoRouterRefreshStream(
    ref.watch(supabaseClientProvider).auth.onAuthStateChange,
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      final session = ref.read(supabaseClientProvider).auth.currentSession;
      final onAuthScreen = loc == Routes.login || loc == Routes.register;

      if (session == null) {
        return onAuthScreen ? null : Routes.login;
      }

      // Signed in: figure out the role to pick the right shell.
      final profileAsync = ref.read(currentUserProfileProvider);
      return profileAsync.when(
        data: (user) {
          if (user == null) {
            // handle_new_auth_user() trigger may still be provisioning the
            // row right after sign-up — stay on splash briefly, it retries
            // automatically because authStateChanges keeps refreshing.
            return loc == Routes.splash ? null : Routes.splash;
          }
          if (onAuthScreen || loc == Routes.splash) return _homeFor(user.role);
          return null;
        },
        loading: () => loc == Routes.splash ? null : Routes.splash,
        error: (_, _) => Routes.login,
      );
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.configMissing, builder: (_, _) => const ConfigMissingScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.adminHome,
        builder: (_, _) => const RoleHomeScreen(roleLabel: 'لوحة تحكم الأدمن', icon: Icons.admin_panel_settings_outlined),
      ),
      GoRoute(
        path: Routes.technicianHome,
        builder: (_, _) => const RoleHomeScreen(roleLabel: 'تطبيق الصنايعي', icon: Icons.build_outlined),
      ),
      GoRoute(
        path: Routes.customerHome,
        builder: (_, _) => const RoleHomeScreen(roleLabel: 'معرض أجهزة البخار', icon: Icons.storefront_outlined),
      ),
    ],
  );
}

String _homeFor(AppRole role) => switch (role) {
      AppRole.admin => Routes.adminHome,
      AppRole.technician => Routes.technicianHome,
      AppRole.customer => Routes.customerHome,
    };
