import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/constants/brand.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../../products/data/models/product_public.dart';
import '../../../../products/presentation/widgets/product_card.dart';
import '../../../data/models/storefront_models.dart';
import '../../providers/storefront_providers.dart';

/// «الرئيسية»: where the customer lands. Sections with nothing in them are
/// simply not shown, so an empty catalogue still looks deliberate.
///
/// Layout (redesigned per the user's 2026-09-17 request): a plain branded
/// app bar, a proper greeting header, then a single "hero" slot right under
/// the name — live offers if there are any, otherwise the maintenance CTA
/// (never both at once, so the hero slot is never empty and never doubled
/// up). The old address/coverage bar and the categories row are gone;
/// "newest" now sits where categories used to.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(customerHomeProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final firstName = profile?.fullName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(Brand.name),
        actions: const [NotificationBellIcon()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerHomeProvider);
          await ref.read(customerHomeProvider.future);
        },
        child: homeAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              ErrorView(
                message: 'تعذَّر تحميل الصفحة الرئيسية',
                onRetry: () => ref.invalidate(customerHomeProvider),
              ),
            ],
          ),
          data: (home) => ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _GreetingHeader(firstName: firstName),
              if (home.offers.isNotEmpty)
                _Offers(home.offers)
              else
                const _MaintenanceCard(),
              if (home.banners.isNotEmpty) _BannerCarousel(home.banners),
              const _QuickActions(),
              if (home.newest.isNotEmpty)
                _ProductRow(
                  key: const Key('home-newest'),
                  title: 'وصل حديثًا',
                  products: home.newest,
                ),
              if (home.featured.isNotEmpty)
                _ProductRow(
                  key: const Key('home-featured'),
                  title: 'مختارات مكوجي',
                  products: home.featured,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens whatever a banner points at.
void openBannerTarget(BuildContext context, HomeBanner banner) {
  switch (banner.targetType) {
    case BannerTarget.offer:
      context.push(Routes.customerOffer(banner.targetId!));
    case BannerTarget.category:
      context.go(Routes.customerStoreCategory(banner.targetId!));
    case BannerTarget.product:
      context.push(Routes.customerProductDetail(banner.targetId!));
    case BannerTarget.maintenance:
      context.push(Routes.customerMaintenanceNew);
    case BannerTarget.none:
      break;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader(this.title, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// The proper "أهلًا، اسم" greeting — this is the section that replaced the
/// old address/coverage bar; the app bar itself now just carries the brand.
class _GreetingHeader extends StatelessWidget {
  final String? firstName;
  const _GreetingHeader({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        firstName == null || firstName!.isEmpty
            ? 'أهلًا بيك 👋'
            : 'أهلًا، $firstName 👋',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<HomeBanner> banners;
  const _BannerCarousel(this.banners);

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        final next = (_page + 1) % widget.banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 2.2,
          child: PageView.builder(
            key: const Key('home-banners'),
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  label: b.title,
                  button: b.targetType != BannerTarget.none,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: AppColors.accentSoft,
                      child: InkWell(
                        onTap: b.targetType == BannerTarget.none
                            ? null
                            : () => openBannerTarget(context, b),
                        child: CachedNetworkImage(
                          imageUrl: b.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              b.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Iconsax.setting_2_copy,
        label: 'طلب صيانة',
        onTap: () => context.push(Routes.customerMaintenanceNew),
      ),
      (
        icon: Iconsax.shop_copy,
        label: 'كل المنتجات',
        onTap: () => context.go(Routes.customerStore),
      ),
      (
        icon: Iconsax.receipt_text_copy,
        label: 'طلباتي',
        onTap: () => context.go(Routes.customerOrders),
      ),
      (
        icon: Iconsax.location_copy,
        label: 'عناويني',
        onTap: () => context.push(Routes.customerAddresses),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          for (final a in actions)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: a.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(a.icon, color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Offers extends StatelessWidget {
  final List<Offer> offers;
  const _Offers(this.offers);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('عروض خاصة'),
        SizedBox(
          height: 150,
          child: ListView.separated(
            key: const Key('home-offers'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                SizedBox(width: 260, child: OfferCard(offer: offers[i])),
          ),
        ),
      ],
    );
  }
}

/// An offer tile: image (or brand gradient), badge and title.
class OfferCard extends StatelessWidget {
  final Offer offer;
  const OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        child: InkWell(
          onTap: () => context.push(Routes.customerOffer(offer.id)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (offer.imageUrl != null)
                CachedNetworkImage(imageUrl: offer.imageUrl!, fit: BoxFit.cover)
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.brandTeal],
                    ),
                  ),
                ),
              // Keeps the text legible on any image.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offer.badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          offer.badgeText!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (offer.subtitle != null)
                      Text(
                        offer.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String title;
  final List<ProductPublic> products;

  const _ProductRow({super.key, required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title,
          actionLabel: 'عرض الكل',
          onAction: () => context.go(Routes.customerStore),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                SizedBox(width: 160, child: ProductCard(product: products[i])),
          ),
        ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandNavy, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Iconsax.setting_2_copy,
              color: AppColors.brandGold,
              size: 40,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مكواتك محتاجة صيانة؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'اطلب فني وتابع دورك لحظة بلحظة',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGold,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => context.push(Routes.customerMaintenanceNew),
              child: const Text('اطلب الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
