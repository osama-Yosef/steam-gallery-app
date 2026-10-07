import 'package:flutter/foundation.dart';

/// A search over past records (orders, maintenance requests): free text
/// and an optional day range. Used as a provider family key, hence the
/// value equality.
@immutable
class HistoryQuery {
  /// A record number, or part of a name / phone.
  final String text;

  /// First day included (local date), or null for no lower bound.
  final DateTime? from;

  /// Last day included (local date), or null for no upper bound.
  final DateTime? to;

  const HistoryQuery({this.text = '', this.from, this.to});

  HistoryQuery copyWith({
    String? text,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) => HistoryQuery(
    text: text ?? this.text,
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
  );

  String get trimmedText => text.trim();

  /// The text as a record number, when it is one ("12" or "#12").
  int? get number => int.tryParse(trimmedText.replaceFirst('#', ''));

  /// The text with the characters PostgREST's `or=(...)` filter syntax
  /// treats specially removed, so a typed comma or bracket can't break the
  /// query (or widen it) — and the "#" people type before a number.
  String get safeText =>
      trimmedText.replaceAll(RegExp(r'[,()*%\\.:"#]'), ' ').trim();

  /// Inclusive start of [from] as a UTC instant, for `created_at >= …`.
  String? get fromUtc => from == null
      ? null
      : DateTime(from!.year, from!.month, from!.day).toUtc().toIso8601String();

  /// Exclusive end of [to] (the next midnight) as a UTC instant, for
  /// `created_at < …`.
  String? get toUtcExclusive => to == null
      ? null
      : DateTime(to!.year, to!.month, to!.day + 1).toUtc().toIso8601String();

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery &&
      other.text == text &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(text, from, to);
}

/// Midnight today (local) as a UTC instant — where "today's" records start.
String startOfTodayUtc([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day).toUtc().toIso8601String();
}

/// One screenful of history results plus what the list needs to keep
/// loading more as it scrolls.
@immutable
class HistoryPage<T> {
  final List<T> items;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;

  const HistoryPage({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  HistoryPage<T> copyWith({bool? loadingMore, bool? loadMoreFailed}) =>
      HistoryPage(
        items: items,
        hasMore: hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );

  /// This page followed by [next], fetched with a page size of [pageSize].
  HistoryPage<T> append(List<T> next, int pageSize) =>
      HistoryPage(items: [...items, ...next], hasMore: next.length == pageSize);
}

/// How many history rows are fetched at a time.
const historyPageSize = 30;
