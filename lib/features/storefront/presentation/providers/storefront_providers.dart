import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../products/data/models/product_public.dart';
import '../../data/models/storefront_models.dart';
import '../../data/repositories/storefront_repository.dart';

part 'storefront_providers.g.dart';

@Riverpod(keepAlive: true)
StorefrontRepository storefrontRepository(Ref ref) {
  return SupabaseStorefrontRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<CustomerHomeData> customerHome(Ref ref) {
  return ref.watch(storefrontRepositoryProvider).getCustomerHome();
}

@riverpod
Future<Offer?> offerDetail(Ref ref, String offerId) {
  return ref.watch(storefrontRepositoryProvider).getOffer(offerId);
}

@riverpod
Future<List<ProductPublic>> offerProducts(Ref ref, String offerId) {
  return ref.watch(storefrontRepositoryProvider).getOfferProducts(offerId);
}

@riverpod
Future<List<HomeBanner>> adminBanners(Ref ref) {
  return ref.watch(storefrontRepositoryProvider).listBannersAdmin();
}

@riverpod
Future<List<Offer>> adminOffers(Ref ref) {
  return ref.watch(storefrontRepositoryProvider).listOffersAdmin();
}
