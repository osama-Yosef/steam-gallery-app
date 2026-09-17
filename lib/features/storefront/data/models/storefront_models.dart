import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../products/data/models/product_category.dart';
import '../../../products/data/models/product_public.dart';

part 'storefront_models.freezed.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

/// A special offer (0033). Promotional content only — it never changes a
/// product's price; orders always charge products.selling_price.
@freezed
abstract class Offer with _$Offer {
  const Offer._();

  const factory Offer({
    required String id,
    required String title,
    String? subtitle,
    String? description,
    String? badgeText,
    String? imageUrl,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool isActive,
    required int sortOrder,
  }) = _Offer;

  factory Offer.fromRow(Map<String, dynamic> row) => Offer(
    id: row['id'] as String,
    title: row['title'] as String,
    subtitle: row['subtitle'] as String?,
    description: row['description'] as String?,
    badgeText: row['badge_text'] as String?,
    imageUrl: row['image_url'] as String?,
    startsAt: _date(row['starts_at']),
    endsAt: _date(row['ends_at']),
    isActive: row['is_active'] as bool? ?? false,
    sortOrder: row['sort_order'] as int? ?? 0,
  );

  /// Same rule as public.is_live(): on, and inside its optional schedule.
  /// The server applies it for customers; the admin list uses this to label.
  bool isLiveAt(DateTime now) =>
      isActive &&
      (startsAt == null || !startsAt!.isAfter(now)) &&
      (endsAt == null || endsAt!.isAfter(now));
}

enum BannerTarget { none, offer, category, product, maintenance }

BannerTarget bannerTargetFromString(String v) => BannerTarget.values.firstWhere(
  (t) => t.name == v,
  orElse: () => BannerTarget.none,
);

/// Whether a target needs an id (mirrors the table's CHECK).
bool bannerTargetNeedsId(BannerTarget t) =>
    t == BannerTarget.offer ||
    t == BannerTarget.category ||
    t == BannerTarget.product;

String bannerTargetLabelAr(BannerTarget t) => switch (t) {
  BannerTarget.none => 'بدون (صورة فقط)',
  BannerTarget.offer => 'عرض',
  BannerTarget.category => 'قسم',
  BannerTarget.product => 'منتج',
  BannerTarget.maintenance => 'طلب صيانة',
};

@freezed
abstract class HomeBanner with _$HomeBanner {
  const HomeBanner._();

  const factory HomeBanner({
    required String id,
    required String title,
    required String imageUrl,
    required BannerTarget targetType,
    String? targetId,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool isActive,
    required int sortOrder,
  }) = _HomeBanner;

  factory HomeBanner.fromRow(Map<String, dynamic> row) => HomeBanner(
    id: row['id'] as String,
    title: row['title'] as String,
    imageUrl: row['image_url'] as String,
    targetType: bannerTargetFromString(row['target_type'] as String),
    targetId: row['target_id'] as String?,
    startsAt: _date(row['starts_at']),
    endsAt: _date(row['ends_at']),
    isActive: row['is_active'] as bool? ?? false,
    sortOrder: row['sort_order'] as int? ?? 0,
  );

  bool isLiveAt(DateTime now) =>
      isActive &&
      (startsAt == null || !startsAt!.isAfter(now)) &&
      (endsAt == null || endsAt!.isAfter(now));
}

/// Everything the customer home screen shows, fetched in one go.
class CustomerHomeData {
  final List<HomeBanner> banners;
  final List<Offer> offers;
  final List<ProductCategory> categories;
  final List<ProductPublic> featured;
  final List<ProductPublic> newest;

  const CustomerHomeData({
    required this.banners,
    required this.offers,
    required this.categories,
    required this.featured,
    required this.newest,
  });

  bool get isEmpty =>
      banners.isEmpty &&
      offers.isEmpty &&
      categories.isEmpty &&
      featured.isEmpty &&
      newest.isEmpty;
}

/// Admin input for an offer. [id] null = new.
class OfferInput {
  final String? id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? badgeText;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int sortOrder;
  final List<String> productIds;

  const OfferInput({
    this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.badgeText,
    this.imageUrl,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    this.sortOrder = 0,
    this.productIds = const [],
  });
}

/// Admin input for a banner. [id] null = new.
class BannerInput {
  final String? id;
  final String title;
  final String imageUrl;
  final BannerTarget targetType;
  final String? targetId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int sortOrder;

  const BannerInput({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.targetType,
    this.targetId,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    this.sortOrder = 0,
  });
}
