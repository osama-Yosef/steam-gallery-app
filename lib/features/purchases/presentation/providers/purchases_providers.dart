import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/purchase_models.dart';
import '../../data/repositories/purchases_repository.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../core/offline/outbox.dart';

part 'purchases_providers.g.dart';

@Riverpod(keepAlive: true)
PurchasesRepository purchasesRepository(Ref ref) {
  return SupabasePurchasesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(outboxProvider),
  );
}

@riverpod
Future<List<SupplierBalance>> suppliers(Ref ref) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref.watch(purchasesRepositoryProvider).getSuppliers();
}

@riverpod
Future<List<PurchaseInvoice>> purchaseInvoices(Ref ref, {String? supplierId}) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref
      .watch(purchasesRepositoryProvider)
      .getInvoices(supplierId: supplierId);
}

@riverpod
Future<PurchaseInvoice> purchaseInvoice(Ref ref, String id) {
  ref.refreshOnServerChange();
  return ref.watch(purchasesRepositoryProvider).getInvoice(id);
}

@riverpod
Future<List<PurchaseInvoiceItem>> purchaseInvoiceItems(Ref ref, String id) {
  return ref.watch(purchasesRepositoryProvider).getInvoiceItems(id);
}

@riverpod
Future<List<SupplierPayment>> purchaseInvoicePayments(Ref ref, String id) {
  ref.refreshOnServerChange();
  return ref.watch(purchasesRepositoryProvider).getInvoicePayments(id);
}
