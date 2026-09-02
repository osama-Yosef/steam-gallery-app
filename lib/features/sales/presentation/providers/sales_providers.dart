import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/repositories/sales_repository.dart';

part 'sales_providers.g.dart';

@Riverpod(keepAlive: true)
SalesRepository salesRepository(Ref ref) {
  return SupabaseSalesRepository(ref.watch(supabaseClientProvider));
}
