import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/brand.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../providers/auth_providers.dart';

/// Shown while the router waits for [currentUserProfileProvider] to resolve
/// after sign-in. Normally that's near-instant; the only expected delay is
/// the trigger provisioning a brand-new signup's public.users row. If the
/// profile is still missing after a few seconds — e.g. a row that
/// (for whatever reason) no longer exists for an otherwise-valid session —
/// there is nothing left to wait for, so this signs the session out instead
/// of spinning forever with no way back to the login screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _maxChecks = 4; // 4 * 8s = 32s total before giving up anyway

  Timer? _timeout;
  int _checks = 0;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  void _scheduleCheck() {
    _timeout = Timer(const Duration(seconds: 8), _giveUpIfStillStuck);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _giveUpIfStillStuck() async {
    if (!mounted) return;
    final profileAsync = ref.read(currentUserProfileProvider);
    if (profileAsync.value != null) return; // resolved fine — not stuck
    _checks++;
    if (profileAsync.isLoading && _checks < _maxChecks) {
      // Still legitimately in flight (e.g. a slow connection) — check again
      // rather than declaring it stuck after a single 8s window, but don't
      // wait forever either: a one-shot timer that never reschedules while
      // still loading would leave the user stuck here with no way back.
      _scheduleCheck();
      return;
    }
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The logo already carries the wordmark — no separate title.
            const BrandLogo(width: 150),
            const SizedBox(height: 16),
            Text(
              Brand.tagline,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
