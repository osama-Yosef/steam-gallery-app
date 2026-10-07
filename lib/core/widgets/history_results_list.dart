import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../utils/history_query.dart';
import 'state_views.dart';

/// The results of a history search: built lazily, and asking for the next
/// page ([onLoadMore]) as the end of the list comes into view.
class HistoryResultsList<T> extends StatelessWidget {
  final AsyncValue<HistoryPage<T>> results;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final String emptyMessage;

  const HistoryResultsList({
    super.key,
    required this.results,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRetry,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return results.when(
      // A new search keeps showing the previous results until it lands.
      skipLoadingOnReload: true,
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: 'تعذَّر تحميل السجل', onRetry: onRetry),
      data: (page) {
        if (page.items.isEmpty) {
          return EmptyView(
            message: emptyMessage,
            icon: Iconsax.search_status_copy,
          );
        }
        final footer = page.hasMore || page.loadMoreFailed ? 1 : 0;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: page.items.length + footer,
          itemBuilder: (context, i) {
            if (i < page.items.length) {
              return itemBuilder(context, page.items[i]);
            }
            if (page.loadMoreFailed) {
              return Center(
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Iconsax.refresh_copy),
                  label: const Text('تعذَّر تحميل المزيد — حاول تاني'),
                ),
              );
            }
            // The last row coming into view asks for the next page.
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        );
      },
    );
  }
}
