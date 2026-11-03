import 'package:supabase_flutter/supabase_flutter.dart';

/// The server returns at most this many rows per request.
const serverPageSize = 1000;

/// Every row of [query], a page at a time — without this a long range
/// silently stops at the first [serverPageSize] rows. [query] must be
/// ordered on a unique column so pages don't overlap.
Future<List<Map<String, dynamic>>> allRows(
  PostgrestTransformBuilder<List<Map<String, dynamic>>> Function() query,
) => readAllPages((from, to) => query().range(from, to));

/// Calls [page] with consecutive inclusive ranges until one comes back
/// short. Split out of [allRows] so it can be tested without a server.
Future<List<T>> readAllPages<T>(
  Future<List<T>> Function(int from, int to) page, {
  int size = serverPageSize,
}) async {
  final rows = <T>[];
  while (true) {
    final batch = await page(rows.length, rows.length + size - 1);
    rows.addAll(batch);
    if (batch.length < size) return rows;
  }
}
