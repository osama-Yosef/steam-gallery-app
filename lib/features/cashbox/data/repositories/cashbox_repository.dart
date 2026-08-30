import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/cash_transaction.dart';
import '../models/cashbox_balance.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

abstract class CashboxRepository {
  /// v1 has exactly one active cashbox — see docs/02-database-design.md.
  Future<CashboxBalance?> getBalance();

  Future<List<CashTransaction>> getCashTransactions({int limit = 200});

  Future<List<ExpenseCategory>> getExpenseCategories();

  Future<List<Expense>> getExpenses({int limit = 200});

  Future<void> recordExpense({
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    String? notes,
  });
}

class SupabaseCashboxRepository implements CashboxRepository {
  final SupabaseClient _client;
  SupabaseCashboxRepository(this._client);

  @override
  Future<CashboxBalance?> getBalance() async {
    try {
      final row = await _client.from('cashbox_balances').select().limit(1).maybeSingle();
      return row == null ? null : CashboxBalance.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<CashTransaction>> getCashTransactions({int limit = 200}) async {
    try {
      final rows =
          await _client.from('cash_transactions').select().order('created_at', ascending: false).limit(limit);
      return rows.map(CashTransaction.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final rows = await _client.from('expense_categories').select().eq('is_active', true).order('name');
      return rows.map(ExpenseCategory.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<Expense>> getExpenses({int limit = 200}) async {
    try {
      final rows = await _client
          .from('expenses')
          .select('id, expense_number, amount, expense_date, notes, created_at, expense_categories(name)')
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(Expense.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> recordExpense({
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    String? notes,
  }) async {
    try {
      await _client.rpc('rpc_record_expense', params: {
        'p_category_id': categoryId,
        'p_amount': amount,
        'p_expense_date': expenseDate.toIso8601String().split('T').first,
        'p_notes': notes,
        'p_attachment_url': null,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
