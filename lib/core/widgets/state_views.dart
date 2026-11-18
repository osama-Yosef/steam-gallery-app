import 'package:flutter/material.dart';
import '../offline/network_status.dart';
import '../theme/app_colors.dart';

/// The three states every async-data screen must handle explicitly
/// (see docs/05-flutter-architecture.md §9). Pair with AsyncValue.when(...).

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// While the server can't be reached, an error here almost always means
/// "nothing saved on this device for this screen yet" — so it says that,
/// instead of a failure, and retries by itself once the connection is back.
class ErrorView extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  static const offlineMessage = 'البيانات دي هتظهر لما النت يرجع';

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  NetworkStatus get _network => NetworkStatus.instance;
  late bool _offline = !_network.isOnline;

  @override
  void initState() {
    super.initState();
    _network.addListener(_onNetwork);
  }

  @override
  void dispose() {
    _network.removeListener(_onNetwork);
    super.dispose();
  }

  void _onNetwork() {
    final offline = !_network.isOnline;
    if (offline == _offline) return;
    setState(() => _offline = offline);
    if (!offline) widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    final onRetry = widget.onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _offline ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: _offline
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _offline ? ErrorView.offlineMessage : widget.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSoft,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              SizedBox(width: 240, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}
