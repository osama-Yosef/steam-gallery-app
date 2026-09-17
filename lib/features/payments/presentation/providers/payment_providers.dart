import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/payment_models.dart';
import '../../data/repositories/payment_repository.dart';

part 'payment_providers.g.dart';

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) {
  return SupabasePaymentRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<InstapayDetails> instapayDetails(Ref ref) {
  return ref.watch(paymentRepositoryProvider).getInstapayDetails();
}

@riverpod
Future<List<PaymentRecord>> myPayments(Ref ref) {
  return ref.watch(paymentRepositoryProvider).getMyPayments();
}

/// Admin review queue.
@riverpod
Future<List<PaymentRecord>> pendingInstapaySubmissions(Ref ref) {
  return ref.watch(paymentRepositoryProvider).getPendingInstapaySubmissions();
}
