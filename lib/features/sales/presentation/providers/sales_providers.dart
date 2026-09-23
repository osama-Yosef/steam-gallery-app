import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../technician_account/data/models/sale.dart';
import '../../data/models/sale_return_item.dart';
import '../../data/repositories/sales_repository.dart';

part 'sales_providers.g.dart';

@Riverpod(keepAlive: true)
SalesRepository salesRepository(Ref ref) {
  return SupabaseSalesRepository(ref.watch(supabaseClientProvider));
}

// keepAlive: a plain @riverpod stream provider is disposed the instant it
// has zero watchers (e.g. an in-flight rebuild between frames) and rebuilt
// from scratch on the next watch — for a Supabase realtime stream that means
// resubscribing the channel, which briefly resets the screen to its loading
// state every time. Same fix as myNotifications/visibleMaintenanceRequests;
// found live as this screen's "opens, then flickers loading on and off".
@Riverpod(keepAlive: true)
Stream<List<Sale>> walkInSales(Ref ref) {
  return ref.watch(salesRepositoryProvider).watchWalkInSales();
}

@Riverpod(keepAlive: true)
Future<List<SaleReturnItem>> saleReturnItems(Ref ref, String saleId) {
  return ref.watch(salesRepositoryProvider).getSaleItems(saleId);
}

@Riverpod(keepAlive: true)
Future<Sale> saleById(Ref ref, String saleId) {
  return ref.watch(salesRepositoryProvider).getSale(saleId);
}
