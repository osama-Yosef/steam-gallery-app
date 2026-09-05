import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_category.freezed.dart';

@freezed
abstract class ExpenseCategory with _$ExpenseCategory {
  const factory ExpenseCategory({
    required String id,
    required String name,
    required bool isActive,
  }) = _ExpenseCategory;

  factory ExpenseCategory.fromRow(Map<String, dynamic> row) => ExpenseCategory(
    id: row['id'] as String,
    name: row['name'] as String,
    isActive: row['is_active'] as bool,
  );
}
