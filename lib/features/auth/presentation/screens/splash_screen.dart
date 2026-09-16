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
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
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
    if (profileAsync.isLoading) {
      return; // still legitimately in flight — not stuck
    }
    if (profileAsync.value != null) return; // resolved fine — not stuck
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
