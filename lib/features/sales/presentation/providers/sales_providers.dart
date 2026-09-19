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

@riverpod
Stream<List<Sale>> walkInSales(Ref ref) {
  return ref.watch(salesRepositoryProvider).watchWalkInSales();
}

@riverpod
Future<List<SaleReturnItem>> saleReturnItems(Ref ref, String saleId) {
  return ref.watch(salesRepositoryProvider).getSaleItems(saleId);
}
