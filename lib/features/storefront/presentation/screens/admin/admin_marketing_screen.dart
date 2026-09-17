import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../providers/storefront_providers.dart';

/// Admin → العروض والبانرات. Two lists; each row says whether customers see
/// it right now (on AND within its schedule).
class AdminMarketingScreen extends ConsumerWidget {
  const AdminMarketingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('العروض والبانرات'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'العروض'),
                Tab(text: 'البانرات'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final isOffers = DefaultTabController.of(context).index == 0;
              context.push(
                isOffers ? Routes.adminOfferNew : Routes.adminBannerNew,
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة'),
          ),
          body: const TabBarView(children: [_OffersTab(), _BannersTab()]),
        ),
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  final bool live;
  final bool isActive;
  const _LiveChip({required this.live, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final (String text, Color color) = live
        ? ('ظاهر للعملاء', AppColors.success)
        : isActive
        ? ('خارج فترة العرض', AppColors.warning)
        : ('متوقف', AppColors.textSecondary);
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    );
  }
}

String _schedule(DateTime? starts, DateTime? ends) {
  if (starts == null && ends == null) return 'بدون مدة';
  return [
    if (starts != null) 'من ${Formatters.date(starts)}',
    if (ends != null) 'حتى ${Formatters.date(ends)}',
  ].join(' ');
}

Widget _thumb(String? url, IconData fallback) => ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: SizedBox(
    width: 64,
    height: 44,
    child: url == null
        ? ColoredBox(
            color: AppColors.accentSoft,
            child: Icon(fallback, color: AppColors.primary),
          )
        : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
  ),
);

class _OffersTab extends ConsumerWidget {
  const _OffersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(adminOffersProvider);
    final now = DateTime.now();
    return offersAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'تعذَّر تحميل العروض',
        onRetry: () => ref.invalidate(adminOffersProvider),
      ),
      data: (offers) => offers.isEmpty
          ? const EmptyView(
              message:
                  'لا توجد عروض بعد.\nالعروض للتسويق فقط ولا تغيّر أسعار المنتجات.',
              icon: Icons.local_offer_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final o = offers[i];
                return ListTile(
                  leading: _thumb(o.imageUrl, Icons.local_offer_outlined),
                  title: Text(o.title),
                  subtitle: Text(_schedule(o.startsAt, o.endsAt)),
                  trailing: _LiveChip(
                    live: o.isLiveAt(now),
                    isActive: o.isActive,
                  ),
                  onTap: () => context.push(Routes.adminOfferEdit(o.id)),
                );
              },
            ),
    );
  }
}

class _BannersTab extends ConsumerWidget {
  const _BannersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);
    final now = DateTime.now();
    return bannersAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'تعذَّر تحميل البانرات',
        onRetry: () => ref.invalidate(adminBannersProvider),
      ),
      data: (banners) => banners.isEmpty
          ? const EmptyView(
              message: 'لا توجد بانرات بعد',
              icon: Icons.view_carousel_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: banners.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = banners[i];
                return ListTile(
                  leading: _thumb(b.imageUrl, Icons.image_outlined),
                  title: Text(b.title),
                  subtitle: Text(_schedule(b.startsAt, b.endsAt)),
                  trailing: _LiveChip(
                    live: b.isLiveAt(now),
                    isActive: b.isActive,
                  ),
                  onTap: () => context.push(Routes.adminBannerEdit(b.id)),
                );
              },
            ),
    );
  }
}
