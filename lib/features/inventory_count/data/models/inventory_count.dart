import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_count.freezed.dart';

enum InventoryCountStatus { draft, completed }

InventoryCountStatus inventoryCountStatusFromString(String v) => switch (v) {
  'draft' => InventoryCountStatus.draft,
  'completed' => InventoryCountStatus.completed,
  _ => InventoryCountStatus.draft,
};

String inventoryCountStatusLabelAr(InventoryCountStatus s) => switch (s) {
  InventoryCountStatus.draft => 'مسودة',
  InventoryCountStatus.completed => 'مُعتمَد',
};

/// What a count is worth at cost (0096): the stock as counted, as the system
/// had it, and the shortage and surplus between them.
class InventoryCountValues {
  final double countedValue;
  final double systemValue;
  final double shortageValue;
  final double surplusValue;
  final int shortageCount;
  final int surplusCount;

  const InventoryCountValues({
    required this.countedValue,
    required this.systemValue,
    required this.shortageValue,
    required this.surplusValue,
    required this.shortageCount,
    required this.surplusCount,
  });

  factory InventoryCountValues.fromRow(Map<String, dynamic> r) {
    double n(String k) => (r[k] as num? ?? 0).toDouble();
    return InventoryCountValues(
      countedValue: n('counted_value'),
      systemValue: n('system_value'),
      shortageValue: n('shortage_value'),
      surplusValue: n('surplus_value'),
      shortageCount: (r['shortage_count'] as num? ?? 0).toInt(),
      surplusCount: (r['surplus_count'] as num? ?? 0).toInt(),
    );
  }
}

@freezed
abstract class InventoryCount with _$InventoryCount {
  const factory InventoryCount({
    required String id,
    required int countNumber,
    required InventoryCountStatus status,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,
    @Default(false) bool isBag,

    /// The warehouse's or bag's id.
    String? locationId,

    /// The bag's technician (0089) — filled in by the repository, null for
    /// the warehouse.
    String? technicianName,

    /// The technician sent his own bag count for review (0089); it's
    /// read-only for him from then on.
    DateTime? submittedAt,

    /// At cost (inventory_count_values, 0096) — filled in by the
    /// repository; null on a database without it.
    InventoryCountValues? values,
  }) = _InventoryCount;

  const InventoryCount._();

  bool get isDraft => status == InventoryCountStatus.draft;

  /// The last thing that happened to it: approved, sent, or started.
  DateTime get lastActivityAt => completedAt ?? submittedAt ?? startedAt;

  /// Waiting for admin/sales to approve a technician's count.
  bool get awaitsApproval => isDraft && submittedAt != null;

  String get title =>
      isBag ? 'جرد شنطة ${technicianName ?? 'صنايعي'}' : 'جرد المخزن الرئيسي';

  String get statusLabelAr =>
      awaitsApproval ? 'بانتظار الاعتماد' : inventoryCountStatusLabelAr(status);

  factory InventoryCount.fromRow(Map<String, dynamic> row) => InventoryCount(
    id: row['id'] as String,
    countNumber: row['count_number'] as int,
    status: inventoryCountStatusFromString(row['status'] as String),
    startedAt: DateTime.parse(row['started_at'] as String),
    completedAt: row['completed_at'] == null
        ? null
        : DateTime.parse(row['completed_at'] as String),
    notes: row['notes'] as String?,
    isBag: row['location_type'] == 'technician_bag',
    locationId: row['location_id'] as String?,
    submittedAt: row['submitted_at'] == null
        ? null
        : DateTime.parse(row['submitted_at'] as String),
  );
}
