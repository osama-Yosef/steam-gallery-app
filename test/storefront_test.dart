import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/maps/geo_point.dart';
import 'package:steam_gallery_app/core/router/route_names.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/locations/data/models/location_models.dart';
import 'package:steam_gallery_app/features/locations/presentation/providers/locations_providers.dart';
import 'package:steam_gallery_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:steam_gallery_app/features/products/data/models/product_category.dart';
import 'package:steam_gallery_app/features/products/data/models/product_public.dart';
import 'package:steam_gallery_app/features/storefront/data/models/storefront_models.dart';
import 'package:steam_gallery_app/features/storefront/presentation/providers/storefront_providers.dart';
import 'package:steam_gallery_app/features/storefront/presentation/screens/customer/customer_home_screen.dart';
import 'package:steam_gallery_app/features/storefront/presentation/widgets/marketing_form_parts.dart';

ProductPublic _product(String id, String name, {bool featured = false}) =>
    ProductPublic(
      id: id,
      sku: id,
      name: name,
      specs: const {},
      sellingPrice: 100,
      isAvailable: true,
      createdAt: DateTime(2026, 9, 1),
      isFeatured: featured,
    );

CustomerAddress _address({required bool serviceable}) => CustomerAddress(
  id: 'a',
  cityId: 'cairo',
  serviceAreaId: serviceable ? 'area' : null,
  label: 'المنزل',
  addressLine: 'شارع عباس العقاد',
  location: const GeoPoint(30.05, 31.33),
  isDefault: true,
);

Future<void> _pumpHome(
  WidgetTester tester, {
  required CustomerHomeData home,
  List<CustomerAddress> addresses = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerHomeProvider.overrideWith((ref) async => home),
        myAddressesProvider.overrideWith((ref) async => addresses),
        currentUserProfileProvider.overrideWith((ref) async => null),
        unreadNotificationCountProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: CustomerHomeScreen(),
        ),
      ),
    ),
  );
  // Banners auto-advance on a timer; pump a fixed slice rather than settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('Offer / HomeBanner liveness mirrors public.is_live()', () {
    final now = DateTime(2026, 9, 16, 12);
    Offer offer({bool active = true, DateTime? starts, DateTime? ends}) =>
        Offer(
          id: 'o',
          title: 't',
          isActive: active,
          sortOrder: 0,
          startsAt: starts,
          endsAt: ends,
        );

    test('on with no schedule is live', () {
      expect(offer().isLiveAt(now), isTrue);
    });
    test('off is never live', () {
      expect(offer(active: false).isLiveAt(now), isFalse);
    });
    test('not started yet / already ended are not live', () {
      expect(
        offer(starts: now.add(const Duration(hours: 1))).isLiveAt(now),
        isFalse,
      );
      expect(offer(ends: now).isLiveAt(now), isFalse);
      expect(
        offer(
          starts: now.subtract(const Duration(days: 1)),
          ends: now.add(const Duration(days: 1)),
        ).isLiveAt(now),
        isTrue,
      );
    });

    test('banner rows map target type and id', () {
      final b = HomeBanner.fromRow({
        'id': 'b',
        'title': 'عرض',
        'image_url': 'https://x/b.jpg',
        'target_type': 'category',
        'target_id': 'c1',
        'is_active': true,
        'sort_order': 2,
      });
      expect(b.targetType, BannerTarget.category);
      expect(b.targetId, 'c1');
      expect(bannerTargetFromString('bogus'), BannerTarget.none);
    });

    test('only offer/category/product targets need an id', () {
      expect(BannerTarget.values.where(bannerTargetNeedsId).toSet(), {
        BannerTarget.offer,
        BannerTarget.category,
        BannerTarget.product,
      });
    });
  });

  test('schedule validation matches the table CHECK', () {
    final d = DateTime(2026, 9, 16);
    expect(scheduleError(null, null), isNull);
    expect(scheduleError(d, d.add(const Duration(days: 1))), isNull);
    expect(scheduleError(d, d), isNotNull);
  });

  test('store category route encodes the id as a query parameter', () {
    expect(Routes.customerStoreCategory('abc'), '/customer/store?category=abc');
  });

  group('CustomerHomeScreen', () {
    testWidgets('shows only sections that have content', (tester) async {
      await _pumpHome(
        tester,
        home: CustomerHomeData(
          banners: const [],
          offers: const [
            Offer(
              id: 'o1',
              title: 'توصيل مجاني',
              badgeText: 'مجانًا',
              isActive: true,
              sortOrder: 0,
            ),
          ],
          categories: const [
            ProductCategory(
              id: 'c1',
              name: 'مكاوي',
              sortOrder: 0,
              isActive: true,
            ),
          ],
          featured: [_product('p1', 'مكواة مميزة', featured: true)],
          newest: const [],
        ),
      );

      expect(find.byKey(const Key('home-banners')), findsNothing);
      expect(find.text('عروض خاصة'), findsOneWidget);
      expect(find.text('مجانًا'), findsOneWidget);
      expect(find.text('الأقسام'), findsOneWidget);
      expect(find.text('مكاوي'), findsOneWidget);
      expect(find.byKey(const Key('home-featured')), findsOneWidget);
      expect(find.text('مكواة مميزة'), findsOneWidget);
      expect(find.byKey(const Key('home-newest')), findsNothing);
      // Always there: quick actions and the maintenance card.
      expect(find.text('طلب صيانة'), findsOneWidget);
      expect(find.text('مكواتك محتاجة صيانة؟'), findsOneWidget);
    });

    const empty = CustomerHomeData(
      banners: [],
      offers: [],
      categories: [],
      featured: [],
      newest: [],
    );

    // One pump per case: a ProviderScope's overrides can't change in place.
    testWidgets('delivery bar: no address invites adding one', (tester) async {
      await _pumpHome(tester, home: empty);
      expect(find.textContaining('أضف عنوانك'), findsOneWidget);
    });

    testWidgets('delivery bar: covered default address', (tester) async {
      await _pumpHome(
        tester,
        home: empty,
        addresses: [_address(serviceable: true)],
      );
      expect(find.text('التوصيل إلى المنزل — الخدمة متاحة'), findsOneWidget);
    });

    testWidgets('delivery bar: uncovered default address', (tester) async {
      await _pumpHome(
        tester,
        home: empty,
        addresses: [_address(serviceable: false)],
      );
      expect(
        find.text('التوصيل إلى المنزل — المنطقة غير مغطاة حاليًا'),
        findsOneWidget,
      );
    });
  });
}
