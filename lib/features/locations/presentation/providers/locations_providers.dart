import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/location_models.dart';
import '../../data/repositories/locations_repository.dart';

part 'locations_providers.g.dart';

@Riverpod(keepAlive: true)
LocationsRepository locationsRepository(Ref ref) {
  return SupabaseLocationsRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<City>> cities(Ref ref, {bool activeOnly = true}) {
  return ref
      .watch(locationsRepositoryProvider)
      .getCities(activeOnly: activeOnly);
}

@riverpod
Future<List<ServiceArea>> serviceAreas(
  Ref ref,
  String cityId, {
  bool activeOnly = true,
}) {
  return ref
      .watch(locationsRepositoryProvider)
      .getServiceAreas(cityId, activeOnly: activeOnly);
}

@riverpod
Future<List<CustomerAddress>> myAddresses(Ref ref) {
  return ref.watch(locationsRepositoryProvider).getMyAddresses();
}

@riverpod
Future<String?> myCityId(Ref ref) {
  return ref.watch(locationsRepositoryProvider).getMyCityId();
}

@riverpod
Future<List<Country>> countries(Ref ref) {
  return ref.watch(locationsRepositoryProvider).getCountries();
}
