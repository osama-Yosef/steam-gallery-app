import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/repositories/users_admin_repository.dart';

part 'users_admin_providers.g.dart';

@Riverpod(keepAlive: true)
UsersAdminRepository usersAdminRepository(Ref ref) {
  return SupabaseUsersAdminRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<AppUser>> adminUsersList(
  Ref ref, {
  String? search,
  AppRole? roleFilter,
}) {
  return ref
      .watch(usersAdminRepositoryProvider)
      .listUsers(search: search, roleFilter: roleFilter);
}
