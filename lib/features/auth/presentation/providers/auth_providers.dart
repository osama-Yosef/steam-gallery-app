import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
}

/// Re-fetches the profile row whenever the Supabase auth session changes
/// (sign in / sign out / token refresh). The router watches this to decide
/// which shell (admin/technician/customer/login) to show.
@Riverpod(keepAlive: true)
Future<AppUser?> currentUserProfile(Ref ref) async {
  ref.watch(authStateChangesProvider); // re-run on every auth event
  final repo = ref.watch(authRepositoryProvider);
  return repo.getMyProfile();
}
