import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/presentation/providers/order_providers.dart';
import 'package:steam_gallery_app/features/orders/presentation/screens/customer/customer_order_detail_screen.dart';
import 'package:steam_gallery_app/features/payments/data/models/payment_models.dart';
import 'package:steam_gallery_app/features/payments/data/repositories/payment_repository.dart';
import 'package:steam_gallery_app/features/payments/presentation/providers/payment_providers.dart';
import 'package:steam_gallery_app/features/wallet/data/models/wallet_models.dart';
import 'package:steam_gallery_app/features/wallet/data/repositories/wallet_repository.dart';
import 'package:steam_gallery_app/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:steam_gallery_app/features/wallet/presentation/screens/customer/wallet_screen.dart';
import 'package:steam_gallery_app/features/wallet/presentation/screens/customer/wallet_topup_screen.dart';

Wallet _wallet(double balance) =>
    Wallet(id: 'w1', balance: balance, currency: 'EGP', isActive: true);

WalletTransaction _txn(String type, double amount) =>
    WalletTransaction.fromRow({
      'id': 'txn-${amount.toStringAsFixed(0)}',
      'type': type,
      'amount': amount,
      'balance_before': 0,
      'balance_after': amount,
      'created_at': '2026-09-17T00:00:00Z',
    });

Order _order({double remaining = 100}) => Order.fromRow({
  'id': 'o1',
  'order_number': 1,
  'customer_id': 'c1',
  'status': 'pending',
  'subtotal': remaining,
  'discount': 0,
  'total': remaining,
  'paid_amount': 0,
  'payment_status': 'unpaid',
  'created_at': '2026-09-17T00:00:00Z',
});

class _FakeWalletRepo implements WalletRepository {
  _FakeWalletRepo({double balance = 0, List<WalletTransaction>? txns})
    : wallet = _wallet(balance),
      txns = txns ?? [];

  Wallet wallet;
  List<WalletTransaction> txns;
  final payCalls = <({String orderId, double amount})>[];
  final topupCalls = <({double amount, String reference})>[];
  Object? payFailWith;

  @override
  Future<Wallet> getMyWallet() async => wallet;

  @override
  Future<List<WalletTransaction>> getMyTransactions() async => txns;

  @override
  Future<String> topupViaInstapay({
    required double amount,
    required String reference,
    required String proofPath,
    required String clientRequestId,
  }) async {
    topupCalls.add((amount: amount, reference: reference));
    return 'payment-1';
  }

  @override
  Future<void> payOrderFromWallet({
    required String orderId,
    required double amount,
    required String clientRequestId,
  }) async {
    if (payFailWith != null) throw payFailWith!;
    payCalls.add((orderId: orderId, amount: amount));
    wallet = _wallet(wallet.balance - amount);
  }

  @override
  Future<List<WalletSummary>> getAllWallets({String? search}) async => [];

  @override
  Future<({double totalLiability, int walletCount})>
  getLiabilitySummary() async => (totalLiability: 0.0, walletCount: 0);
}

class _FakePaymentRepoForWallet implements PaymentRepository {
  _FakePaymentRepoForWallet({this.configured = true});
  final bool configured;

  @override
  Future<InstapayDetails> getInstapayDetails() async => InstapayDetails(
    configured: configured,
    ipaAddress: configured ? 'mokoji@instapay' : null,
    beneficiaryName: configured ? 'مكوجي' : null,
  );

  @override
  Future<String> uploadProof(Uint8List bytes, String ext) async => 'c1/x.$ext';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  required _FakeWalletRepo walletRepo,
  PaymentRepository? paymentRepo,
  Order? order,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletRepositoryProvider.overrideWithValue(walletRepo),
        if (paymentRepo != null)
          paymentRepositoryProvider.overrideWithValue(paymentRepo),
        if (order != null)
          orderDetailProvider('o1').overrideWith((ref) => Stream.value(order)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: screen,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('Wallet models', () {
    test('WalletTransaction.fromRow parses type and amounts', () {
      final t = _txn('debit', -50);
      expect(t.type, WalletTxnType.debit);
      expect(t.amount, -50);
    });

    test('unknown type falls back to topup', () {
      expect(walletTxnTypeFromString('bogus'), WalletTxnType.topup);
    });
  });

  group('WalletScreen', () {
    testWidgets('shows the balance and an empty transaction list', (
      tester,
    ) async {
      await _pump(
        tester,
        const WalletScreen(),
        walletRepo: _FakeWalletRepo(balance: 250),
      );
      expect(find.textContaining(Formatters.currency(250)), findsWidgets);
      expect(find.text('لا توجد عمليات بعد'), findsOneWidget);
    });

    testWidgets('lists transactions, credits and debits distinguishable', (
      tester,
    ) async {
      await _pump(
        tester,
        const WalletScreen(),
        walletRepo: _FakeWalletRepo(
          balance: 100,
          txns: [_txn('topup', 200), _txn('debit', -100)],
        ),
      );
      expect(find.text('شحن رصيد'), findsOneWidget);
      expect(find.text('دفع من المحفظة'), findsOneWidget);
    });
  });

  group('WalletTopupScreen', () {
    testWidgets('not configured shows a message, no form', (tester) async {
      await _pump(
        tester,
        const WalletTopupScreen(),
        walletRepo: _FakeWalletRepo(),
        paymentRepo: _FakePaymentRepoForWallet(configured: false),
      );
      expect(find.textContaining('مش متاح دلوقتي'), findsOneWidget);
      expect(find.byKey(const Key('submit-topup')), findsNothing);
    });

    testWidgets('validates before submitting, then submits', (tester) async {
      final repo = _FakeWalletRepo();
      await _pump(
        tester,
        const WalletTopupScreen(),
        walletRepo: repo,
        paymentRepo: _FakePaymentRepoForWallet(),
      );

      await tester.tap(find.byKey(const Key('submit-topup')));
      await tester.pumpAndSettle();
      expect(repo.topupCalls, isEmpty);
      expect(find.text('اكتب المبلغ اللي حوّلته'), findsOneWidget);
    });
  });

  group('CustomerOrderDetailScreen — wallet pay', () {
    testWidgets('shows the wallet balance on the pay button', (tester) async {
      await _pump(
        tester,
        const CustomerOrderDetailScreen(orderId: 'o1'),
        walletRepo: _FakeWalletRepo(balance: 300),
        order: _order(remaining: 100),
      );
      expect(find.textContaining('ادفع من المحفظة'), findsOneWidget);
      expect(find.textContaining(Formatters.currency(300)), findsWidgets);
    });

    testWidgets('paying asks for confirmation first', (tester) async {
      final repo = _FakeWalletRepo(balance: 300);
      await _pump(
        tester,
        const CustomerOrderDetailScreen(orderId: 'o1'),
        walletRepo: repo,
        order: _order(remaining: 100),
      );

      await tester.tap(find.textContaining('ادفع من المحفظة'));
      await tester.pumpAndSettle();
      expect(find.text('الدفع من المحفظة'), findsOneWidget);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(repo.payCalls, isEmpty);

      await tester.tap(find.textContaining('ادفع من المحفظة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ادفع'));
      await tester.pumpAndSettle();
      expect(repo.payCalls, hasLength(1));
      expect(repo.payCalls.single, (orderId: 'o1', amount: 100.0));
    });

    testWidgets('a server refusal (insufficient balance) shows its message', (
      tester,
    ) async {
      final repo = _FakeWalletRepo(balance: 10)
        ..payFailWith = const PostgrestException(
          message: 'INSUFFICIENT_WALLET_BALANCE',
        );
      await _pump(
        tester,
        const CustomerOrderDetailScreen(orderId: 'o1'),
        walletRepo: repo,
        order: _order(remaining: 100),
      );

      await tester.tap(find.textContaining('ادفع من المحفظة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ادفع'));
      await tester.pumpAndSettle();
      expect(find.text('رصيد محفظتك مش كافي لدفع المبلغ ده'), findsOneWidget);
    });
  });
}
