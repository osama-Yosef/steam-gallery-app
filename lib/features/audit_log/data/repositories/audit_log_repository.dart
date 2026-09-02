import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/audit_log_entry.dart';

abstract class AuditLogRepository {
  /// Admin-only (see 0011_rls_policies.sql) — read-only by design, there is
  /// intentionally no write method here at all.
  Future<List<AuditLogEntry>> listEntries({
    String? tableName,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// Distinct table_name values seen so far, to populate the filter dropdown.
  Future<List<String>> listTableNames();
}

class SupabaseAuditLogRepository implements AuditLogRepository {
  final SupabaseClient _client;
  SupabaseAuditLogRepository(this._client);

  @override
  Future<List<AuditLogEntry>> listEntries({
    String? tableName,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    try {
      var query = _client.from('audit_logs').select('*, users(full_name)');
      if (tableName != null) query = query.eq('table_name', tableName);
      if (from != null) query = query.gte('created_at', from.toIso8601String());
      if (to != null) query = query.lte('created_at', to.toIso8601String());
      final rows = await query.order('created_at', ascending: false).limit(limit);
      return rows.map(AuditLogEntry.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<String>> listTableNames() async {
    try {
      final rows = await _client.from('audit_logs').select('table_name').limit(2000);
      return rows.map((r) => r['table_name'] as String).toSet().toList()..sort();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
