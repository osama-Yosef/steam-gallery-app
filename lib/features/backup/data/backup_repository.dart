import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

/// What a backup file says about itself, read before restoring it.
class BackupInfo {
  final DateTime createdAt;

  /// Rows per table, e.g. 'public.sales' → 120.
  final Map<String, int> rows;

  const BackupInfo({required this.createdAt, required this.rows});

  int of(String table) => rows['public.$table'] ?? 0;

  /// Reads a backup file's bytes; throws [AppException] if they aren't one.
  static (BackupInfo, Map<String, dynamic>) parse(Uint8List bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (json['format'] != 'mokoji-backup' || json['tables'] is! Map) {
        throw const FormatException();
      }
      final tables = (json['tables'] as Map).cast<String, dynamic>();
      return (
        BackupInfo(
          createdAt: DateTime.parse(json['created_at'] as String),
          rows: {
            for (final e in tables.entries) e.key: (e.value as List).length,
          },
        ),
        json,
      );
    } catch (_) {
      throw const AppException('الملف ده مش نسخة احتياطية من التطبيق');
    }
  }
}

/// Full backups (0093): the whole database to a file, and back. Online
/// only — a backup is of the server's data, and a restore replaces it.
class BackupRepository {
  final SupabaseClient _client;
  BackupRepository(this._client);

  /// Every table, as the file's bytes (UTF-8 JSON).
  Future<Uint8List> export() async {
    try {
      final data = await _client.rpc('rpc_backup_export');
      return Uint8List.fromList(utf8.encode(jsonEncode(data)));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Replaces all the data with [backup]'s. All or nothing: on any error
  /// the data is as it was.
  Future<void> restore(Map<String, dynamic> backup) async {
    try {
      await _client.rpc('rpc_backup_restore', params: {'p_backup': backup});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// The file name for a backup taken at [at], e.g.
  /// `mokoji-backup-2026-11-02-1430.json`.
  static String fileName(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    final t = at.toLocal();
    return 'mokoji-backup-${t.year}-${two(t.month)}-${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}.json';
  }
}
