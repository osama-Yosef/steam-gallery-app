import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_request.freezed.dart';

enum MaintenanceStatus { waiting, assigned, inProgress, completed, cancelled }

MaintenanceStatus maintenanceStatusFromString(String v) => switch (v) {
      'waiting' => MaintenanceStatus.waiting,
      'assigned' => MaintenanceStatus.assigned,
      'in_progress' => MaintenanceStatus.inProgress,
      'completed' => MaintenanceStatus.completed,
      'cancelled' => MaintenanceStatus.cancelled,
      _ => MaintenanceStatus.waiting,
    };

String maintenanceStatusToDb(MaintenanceStatus s) => switch (s) {
      MaintenanceStatus.waiting => 'waiting',
      MaintenanceStatus.assigned => 'assigned',
      MaintenanceStatus.inProgress => 'in_progress',
      MaintenanceStatus.completed => 'completed',
      MaintenanceStatus.cancelled => 'cancelled',
    };

String maintenanceStatusLabelAr(MaintenanceStatus s) => switch (s) {
      MaintenanceStatus.waiting => 'في الانتظار',
      MaintenanceStatus.assigned => 'تم الإسناد',
      MaintenanceStatus.inProgress => 'جاري التنفيذ',
      MaintenanceStatus.completed => 'تم التنفيذ',
      MaintenanceStatus.cancelled => 'ملغي',
    };

const kActiveMaintenanceStatuses = [
  MaintenanceStatus.waiting,
  MaintenanceStatus.assigned,
  MaintenanceStatus.inProgress,
];

@freezed
abstract class MaintenanceRequest with _$MaintenanceRequest {
  const factory MaintenanceRequest({
    required String id,
    required int ticketNumber,
    required String customerId,
    required String customerName,
    required String phone,
    String? address,
    double? latitude,
    double? longitude,
    String? deviceType,
    required String problemDescription,
    String? notes,
    required MaintenanceStatus status,
    String? assignedTechnicianId,
    required DateTime createdAt,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelledReason,
  }) = _MaintenanceRequest;

  factory MaintenanceRequest.fromRow(Map<String, dynamic> row) => MaintenanceRequest(
        id: row['id'] as String,
        ticketNumber: row['ticket_number'] as int,
        customerId: row['customer_id'] as String,
        customerName: row['customer_name'] as String,
        phone: row['phone'] as String,
        address: row['address'] as String?,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        deviceType: row['device_type'] as String?,
        problemDescription: row['problem_description'] as String,
        notes: row['notes'] as String?,
        status: maintenanceStatusFromString(row['status'] as String),
        assignedTechnicianId: row['assigned_technician_id'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        assignedAt: row['assigned_at'] == null ? null : DateTime.parse(row['assigned_at'] as String),
        startedAt: row['started_at'] == null ? null : DateTime.parse(row['started_at'] as String),
        completedAt: row['completed_at'] == null ? null : DateTime.parse(row['completed_at'] as String),
        cancelledAt: row['cancelled_at'] == null ? null : DateTime.parse(row['cancelled_at'] as String),
        cancelledReason: row['cancelled_reason'] as String?,
      );
}
