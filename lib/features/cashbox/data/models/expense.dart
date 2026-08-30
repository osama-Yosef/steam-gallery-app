import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';

@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    required int expenseNumber,
    required String categoryName,
    required double amount,
    required DateTime expenseDate,
    String? notes,
    required DateTime createdAt,
  }) = _Expense;

  factory Expense.fromRow(Map<String, dynamic> row) {
    final category = row['expense_categories'] as Map<String, dynamic>;
    return Expense(
      id: row['id'] as String,
      expenseNumber: row['expense_number'] as int,
      categoryName: category['name'] as String,
      amount: (row['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(row['expense_date'] as String),
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
