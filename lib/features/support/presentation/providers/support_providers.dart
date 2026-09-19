import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/repositories/support_repository.dart';

part 'support_providers.g.dart';

@Riverpod(keepAlive: true)
SupportRepository supportRepository(Ref ref) {
  return SupabaseSupportRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<String?> supportWhatsapp(Ref ref) =>
    ref.watch(supportRepositoryProvider).getWhatsapp();
