import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../technician_account/data/models/sale.dart';
import '../../data/models/invoice_line.dart';
import '../../data/models/sale_return_item.dart';
import '../../data/repositories/sales_repository.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../core/offline/outbox.dart';

part 'sales_providers.g.dart';

@Riverpod(keepAlive: true)
SalesRepository salesRepository(Ref ref) {
  return SupabaseSalesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(outboxProvider),
  );
}

@riverpod
Future<List<Sale>> walkInSales(Ref ref) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref.watch(salesRepositoryProvider).getWalkInSales();
}

@Riverpod(keepAlive: true)
Future<List<SaleReturnItem>> saleReturnItems(Ref ref, String saleId) {
  ref.refreshOnServerChange();
  return ref.watch(salesRepositoryProvider).getSaleItems(saleId);
}

@Riverpod(keepAlive: true)
Future<Sale> saleById(Ref ref, String saleId) {
  ref.refreshOnServerChange();
  return ref.watch(salesRepositoryProvider).getSale(saleId);
}

@riverpod
Future<List<InvoiceLine>> invoiceLines(Ref ref, String saleId) {
  ref.refreshOnServerChange();
  return ref.watch(salesRepositoryProvider).getInvoiceLines(saleId);
}
