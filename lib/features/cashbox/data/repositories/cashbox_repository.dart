import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/utils/formatters.dart';
import '../models/cash_transaction.dart';
import '../models/cashbox_balance.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

abstract class CashboxRepository {
  /// Both tills (0059: cash + transfer), one row each.
  Future<List<CashboxBalance>> getBalances();

  /// [cashboxId] filters to one till; omitted shows both mixed together.
  Future<List<CashTransaction>> getCashTransactions({
    String? cashboxId,
    int limit = 200,
  });

  Future<List<ExpenseCategory>> getExpenseCategories();

  Future<List<Expense>> getExpenses({int limit = 200});

  /// The three writes below work offline (queued in the [Outbox], sent via
  /// rpc_replay so a resend can't book them twice).
  Future<OutboxResult> recordExpense({
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    required CashboxKind kind,
    String? notes,
  });

  /// Cash put into the till from outside the business cycle (opening float,
  /// an owner top-up). Deliberately NOT an expense/sale, so it moves the till
  /// balance without touching any profit figure — see migration 0028.
  Future<OutboxResult> depositCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  });

  /// Cash taken out of the till (drawings, moving cash to the bank). Same
  /// deal: balance only, never profit. Throws if it would overdraw the till.
  Future<OutboxResult> withdrawCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  });
}

class SupabaseCashboxRepository implements CashboxRepository {
  final SupabaseClient _client;
  SupabaseCashboxRepository(this._client);

  @override
  Future<List<CashboxBalance>> getBalances() async {
    try {
      final rows = await _client.from('cashbox_balances').select();
      return rows.map(CashboxBalance.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<CashTransaction>> getCashTransactions({
    String? cashboxId,
    int limit = 200,
  }) async {
    try {
      var query = _client.from('cash_transactions').select();
      if (cashboxId != null) query = query.eq('cashbox_id', cashboxId);
      final rows = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(CashTransaction.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final rows = await _client
          .from('expense_categories')
          .select()
          .eq('is_active', true)
          .order('name');
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
          .select(
            'id, expense_number, amount, expense_date, notes, created_at, expense_categories(name)',
          )
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(Expense.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<OutboxResult> recordExpense({
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    required CashboxKind kind,
    String? notes,
  }) => Outbox.instance.submit(
    rpc: 'rpc_record_expense',
    params: {
      'p_category_id': categoryId,
      'p_amount': amount,
      'p_expense_date': expenseDate.toIso8601String().split('T').first,
      'p_notes': notes,
      'p_attachment_url': null,
      'p_kind': cashboxKindToString(kind),
    },
    label: 'مصروف ${Formatters.currency(amount)}${notes == null ? '' : ' · $notes'}',
    kind: 'cashbox',
    viaReplay: true,
  );

  @override
  Future<OutboxResult> depositCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  }) => Outbox.instance.submit(
    rpc: 'rpc_cashbox_deposit',
    params: {
      'p_amount': amount,
      'p_notes': notes,
      'p_kind': cashboxKindToString(kind),
    },
    label: 'إيداع ${Formatters.currency(amount)} في ${cashboxKindLabelAr(kind)}',
    kind: 'cashbox',
    viaReplay: true,
  );

  @override
  Future<OutboxResult> withdrawCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  }) => Outbox.instance.submit(
    rpc: 'rpc_cashbox_withdraw',
    params: {
      'p_amount': amount,
      'p_notes': notes,
      'p_kind': cashboxKindToString(kind),
    },
    label: 'سحب ${Formatters.currency(amount)} من ${cashboxKindLabelAr(kind)}',
    kind: 'cashbox',
    viaReplay: true,
  );
}
