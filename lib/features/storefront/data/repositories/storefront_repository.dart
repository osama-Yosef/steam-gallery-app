import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../products/data/models/product_category.dart';
import '../../../products/data/models/product_public.dart';
import '../models/storefront_models.dart';

/// Home-screen content (0033). Customers only ever receive live offers and
/// banners — RLS filters them — so the queries below don't have to (and
/// can't be relied on to) filter by schedule.
abstract class StorefrontRepository {
  Future<CustomerHomeData> getCustomerHome();

  Future<Offer?> getOffer(String offerId);

  Future<List<ProductPublic>> getOfferProducts(String offerId);

  // Admin
  Future<List<HomeBanner>> listBannersAdmin();

  Future<void> saveBanner(BannerInput input);

  Future<List<Offer>> listOffersAdmin();

  Future<List<String>> getOfferProductIds(String offerId);

  Future<void> saveOffer(OfferInput input);

  /// Uploads to the public `marketing` bucket; returns the public URL.
  Future<String> uploadMarketingImage({
    required String folder,
    required Uint8List bytes,
    required String ext,
  });
}

class SupabaseStorefrontRepository implements StorefrontRepository {
  final SupabaseClient _client;
  SupabaseStorefrontRepository(this._client);

  static const homeSectionLimit = 10;

  @override
  Future<CustomerHomeData> getCustomerHome() async {
    try {
      final results = await Future.wait([
        _client
            .from('home_banners')
            .select()
            .order('sort_order')
            .order('created_at', ascending: false),
        _client
            .from('offers')
            .select()
            .order('sort_order')
            .order('created_at', ascending: false),
        _client
            .from('product_categories')
            .select()
            .eq('is_active', true)
            .order('sort_order'),
        _client
            .from('products_public')
            .select()
            .eq('is_featured', true)
            .order('featured_sort')
            .order('created_at', ascending: false)
            .limit(homeSectionLimit),
        _client
            .from('products_public')
            .select()
            .order('created_at', ascending: false)
            .limit(homeSectionLimit),
      ]);
      return CustomerHomeData(
        banners: results[0].map(HomeBanner.fromRow).toList(),
        offers: results[1].map(Offer.fromRow).toList(),
        categories: results[2].map(ProductCategory.fromRow).toList(),
        featured: results[3].map(ProductPublic.fromRow).toList(),
        newest: results[4].map(ProductPublic.fromRow).toList(),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Offer?> getOffer(String offerId) async {
    try {
      final row = await _client
          .from('offers')
          .select()
          .eq('id', offerId)
          .maybeSingle();
      return row == null ? null : Offer.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<ProductPublic>> getOfferProducts(String offerId) async {
    try {
      final rows = await _client.rpc(
        'rpc_offer_products',
        params: {'p_offer_id': offerId},
      );
      return (rows as List)
          .map(
            (r) => ProductPublic.fromRow(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<HomeBanner>> listBannersAdmin() async {
    try {
      final rows = await _client
          .from('home_banners')
          .select()
          .order('sort_order')
          .order('created_at', ascending: false);
      return rows.map(HomeBanner.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveBanner(BannerInput input) async {
    try {
      final row = {
        'title': input.title.trim(),
        'image_url': input.imageUrl,
        'target_type': input.targetType.name,
        'target_id': bannerTargetNeedsId(input.targetType)
            ? input.targetId
            : null,
        'starts_at': input.startsAt?.toUtc().toIso8601String(),
        'ends_at': input.endsAt?.toUtc().toIso8601String(),
        'is_active': input.isActive,
        'sort_order': input.sortOrder,
      };
      if (input.id == null) {
        await _client.from('home_banners').insert({
          ...row,
          'created_by': _client.auth.currentUser?.id,
        });
      } else {
        await _client.from('home_banners').update(row).eq('id', input.id!);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<Offer>> listOffersAdmin() async {
    try {
      final rows = await _client
          .from('offers')
          .select()
          .order('sort_order')
          .order('created_at', ascending: false);
      return rows.map(Offer.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<String>> getOfferProductIds(String offerId) async {
    try {
      final rows = await _client
          .from('offer_products')
          .select('product_id')
          .eq('offer_id', offerId)
          .order('sort_order');
      return rows.map((r) => r['product_id'] as String).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveOffer(OfferInput input) async {
    String? blank(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    try {
      final row = {
        'title': input.title.trim(),
        'subtitle': blank(input.subtitle),
        'description': blank(input.description),
        'badge_text': blank(input.badgeText),
        'image_url': input.imageUrl,
        'starts_at': input.startsAt?.toUtc().toIso8601String(),
        'ends_at': input.endsAt?.toUtc().toIso8601String(),
        'is_active': input.isActive,
        'sort_order': input.sortOrder,
      };
      final String offerId;
      if (input.id == null) {
        final inserted = await _client
            .from('offers')
            .insert({...row, 'created_by': _client.auth.currentUser?.id})
            .select('id')
            .single();
        offerId = inserted['id'] as String;
      } else {
        offerId = input.id!;
        await _client.from('offers').update(row).eq('id', offerId);
      }

      // Replace the product set. Not atomic with the offer row, but a partial
      // failure only leaves the links as they were or empty — never touches
      // prices or stock — and saving again repairs it.
      await _client.from('offer_products').delete().eq('offer_id', offerId);
      if (input.productIds.isNotEmpty) {
        await _client.from('offer_products').insert([
          for (var i = 0; i < input.productIds.length; i++)
            {
              'offer_id': offerId,
              'product_id': input.productIds[i],
              'sort_order': i,
            },
        ]);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> uploadMarketingImage({
    required String folder,
    required Uint8List bytes,
    required String ext,
  }) async {
    try {
      final path = '$folder/${const Uuid().v4()}.$ext';
      await _client.storage.from('marketing').uploadBinary(path, bytes);
      return _client.storage.from('marketing').getPublicUrl(path);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
