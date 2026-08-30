import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_option.freezed.dart';

/// Lightweight projection used only to populate the admin's "assign to"
/// dropdown — not the full technician account (that's Module 6+).
@freezed
abstract class TechnicianOption with _$TechnicianOption {
  const factory TechnicianOption({
    required String id,
    required String fullName,
    required String employeeCode,
  }) = _TechnicianOption;

  factory TechnicianOption.fromRow(Map<String, dynamic> row) => TechnicianOption(
        id: row['id'] as String,
        fullName: (row['users'] as Map<String, dynamic>)['full_name'] as String,
        employeeCode: row['employee_code'] as String,
      );
}
