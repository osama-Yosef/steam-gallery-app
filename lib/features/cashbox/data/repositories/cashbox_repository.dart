import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/utils/formatters.dart';
import '../models/cash_transaction.dart';
import '../models/cashbox_balance.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

abstract class CashboxRepository {
  /// The four tills (0080), one row each, in [CashboxKind] order.
  Future<List<CashboxBalance>> getBalances();

  /// [cashboxId] filters to one till; omitted shows both mixed together.
  Future<List<CashTransaction>> getCashTransactions({
    String? cashboxId,
    int limit = 200,
  });

  Future<List<ExpenseCategory>> getExpenseCategories();

  /// Every category, stopped ones too — for the categories screen.
  Future<List<ExpenseCategory>> getAllExpenseCategories();

  /// Admin only (RLS). Online only: a new category has nothing to queue
  /// behind, and a duplicate name must be refused right away.
  Future<void> addExpenseCategory(String name);

  Future<void> setExpenseCategoryActive(String id, bool isActive);

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

  /// Several expense lines at once, all from [kind] on [expenseDate] —
  /// booked together or not at all (rpc_record_expenses, 0080).
  Future<OutboxResult> recordExpenses({
    required List<({String categoryId, double amount, String? notes})> lines,
    required DateTime expenseDate,
    required CashboxKind kind,
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

  /// Money moved from one till to another (e.g. the drawer into the safe at
  /// closing). Balance only, never profit. Throws if [from] can't cover it.
  Future<OutboxResult> transferBetweenTills({
    required CashboxKind from,
    required CashboxKind to,
    required double amount,
    String? notes,
  });
}

class SupabaseCashboxRepository implements CashboxRepository {
  final SupabaseClient _client;
  final Outbox _outbox;
  SupabaseCashboxRepository(this._client, this._outbox);

  @override
  Future<List<CashboxBalance>> getBalances() async {
    try {
      final rows = await _client.from('cashbox_balances').select();
      return rows.map(CashboxBalance.fromRow).toList()
        ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
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
  Future<List<ExpenseCategory>> getAllExpenseCategories() async {
    try {
      final rows = await _client
          .from('expense_categories')
          .select()
          .order('is_active', ascending: false)
          .order('name');
      return rows.map(ExpenseCategory.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> addExpenseCategory(String name) async {
    try {
      await _client.from('expense_categories').insert({'name': name.trim()});
      _outbox.markServerChanged();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setExpenseCategoryActive(String id, bool isActive) async {
    try {
      await _client
          .from('expense_categories')
          .update({'is_active': isActive})
          .eq('id', id);
      _outbox.markServerChanged();
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
  }) => _outbox.submit(
    rpc: 'rpc_record_expense',
    params: {
      'p_category_id': categoryId,
      'p_amount': amount,
      'p_expense_date': expenseDate.toIso8601String().split('T').first,
      'p_notes': notes,
      'p_attachment_url': null,
      'p_kind': cashboxKindToString(kind),
    },
    label:
        'مصروف ${Formatters.currency(amount)}${notes == null ? '' : ' · $notes'}',
    kind: 'cashbox',
    viaReplay: true,
  );

  @override
  Future<OutboxResult> recordExpenses({
    required List<({String categoryId, double amount, String? notes})> lines,
    required DateTime expenseDate,
    required CashboxKind kind,
  }) => _outbox.submit(
    rpc: 'rpc_record_expenses',
    params: {
      'p_items': [
        for (final l in lines)
          {'category_id': l.categoryId, 'amount': l.amount, 'notes': l.notes},
      ],
      'p_expense_date': expenseDate.toIso8601String().split('T').first,
      'p_kind': cashboxKindToString(kind),
    },
    label:
        '${lines.length} بنود مصروفات · ${Formatters.currency(lines.fold<double>(0, (s, l) => s + l.amount))}',
    kind: 'cashbox',
    viaReplay: true,
  );

  @override
  Future<OutboxResult> depositCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  }) => _outbox.submit(
    rpc: 'rpc_cashbox_deposit',
    params: {
      'p_amount': amount,
      'p_notes': notes,
      'p_kind': cashboxKindToString(kind),
    },
    label:
        'إيداع ${Formatters.currency(amount)} في ${cashboxKindLabelAr(kind)}',
    kind: 'cashbox',
    viaReplay: true,
  );

  @override
  Future<OutboxResult> withdrawCash({
    required double amount,
    required CashboxKind kind,
    String? notes,
  }) => _outbox.submit(
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

  @override
  Future<OutboxResult> transferBetweenTills({
    required CashboxKind from,
    required CashboxKind to,
    required double amount,
    String? notes,
  }) => _outbox.submit(
    rpc: 'rpc_cashbox_transfer',
    params: {
      'p_from_kind': cashboxKindToString(from),
      'p_to_kind': cashboxKindToString(to),
      'p_amount': amount,
      'p_notes': notes,
    },
    label:
        'تحويل ${Formatters.currency(amount)} من ${cashboxKindLabelAr(from)} إلى ${cashboxKindLabelAr(to)}',
    kind: 'cashbox',
    viaReplay: true,
  );
}
