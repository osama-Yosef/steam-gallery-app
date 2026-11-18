import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/network_status.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../providers/auth_providers.dart';

/// Signed in, but the profile has never been loaded on this device and the
/// server can't be reached. Login would need the internet too, so this
/// waits here and loads the profile by itself once the connection is back.
class OfflineStartScreen extends ConsumerStatefulWidget {
  const OfflineStartScreen({super.key});

  @override
  ConsumerState<OfflineStartScreen> createState() => _OfflineStartScreenState();
}

class _OfflineStartScreenState extends ConsumerState<OfflineStartScreen> {
  @override
  void initState() {
    super.initState();
    NetworkStatus.instance.addListener(_onNetwork);
  }

  @override
  void dispose() {
    NetworkStatus.instance.removeListener(_onNetwork);
    super.dispose();
  }

  void _onNetwork() {
    if (NetworkStatus.instance.isOnline) _retry();
  }

  void _retry() => ref.invalidate(currentUserProfileProvider);

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(currentUserProfileProvider).isLoading;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(width: 120),
              const SizedBox(height: 24),
              Icon(
                Icons.wifi_off,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'محتاج إنترنت أول مرة عشان نحمّل بياناتك',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'بعد كده التطبيق هيشتغل حتى لو النت قطع',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              loading
                  ? const CircularProgressIndicator()
                  : OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
