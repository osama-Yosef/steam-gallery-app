import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/wallet_models.dart';
import '../../data/repositories/wallet_repository.dart';

part 'wallet_providers.g.dart';

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) {
  return SupabaseWalletRepository(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
class MyWallet extends _$MyWallet {
  @override
  Future<Wallet> build() {
    return ref.watch(walletRepositoryProvider).getMyWallet();
  }

  Future<void> refresh() async {
    final repo = ref.read(walletRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repo.getMyWallet);
  }
}

@riverpod
Future<List<WalletTransaction>> myWalletTransactions(Ref ref) {
  return ref.watch(walletRepositoryProvider).getMyTransactions();
}
