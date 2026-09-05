import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/audit_log_entry.dart';
import '../../data/repositories/audit_log_repository.dart';

part 'audit_log_providers.g.dart';

@Riverpod(keepAlive: true)
AuditLogRepository auditLogRepository(Ref ref) {
  return SupabaseAuditLogRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<AuditLogEntry>> auditLogEntries(
  Ref ref, {
  String? tableName,
  DateTime? from,
  DateTime? to,
}) {
  return ref
      .watch(auditLogRepositoryProvider)
      .listEntries(tableName: tableName, from: from, to: to);
}

@riverpod
Future<List<String>> auditLogTableNames(Ref ref) {
  return ref.watch(auditLogRepositoryProvider).listTableNames();
}
