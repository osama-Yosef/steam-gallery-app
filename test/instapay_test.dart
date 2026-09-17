import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/presentation/providers/order_providers.dart';
import 'package:steam_gallery_app/features/payments/data/models/payment_models.dart';
import 'package:steam_gallery_app/features/payments/data/repositories/payment_repository.dart';
import 'package:steam_gallery_app/features/payments/presentation/providers/payment_providers.dart';
import 'package:steam_gallery_app/features/payments/presentation/screens/admin/admin_instapay_review_screen.dart';
import 'package:steam_gallery_app/features/payments/presentation/screens/customer/instapay_payment_screen.dart';

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

PaymentRecord _payment(
  String id, {
  double amount = 100,
  String reference = 'REF-1',
  String? proofPath = 'c1/proof.jpg',
}) => PaymentRecord.fromRow({
  'id': id,
  'customer_id': 'c1',
  'order_id': 'o1',
  'channel': 'instapay',
  'provider': 'instapay',
  'amount': amount,
  'currency': 'EGP',
  'status': 'pending_verification',
  'provider_reference': reference,
  'metadata': {'proof_path': ?proofPath},
  'created_at': '2026-09-17T00:00:00Z',
});

/// Records calls; [details] controls whether InstaPay looks configured.
class _FakePaymentRepo implements PaymentRepository {
  _FakePaymentRepo({
    this.details = const InstapayDetails(
      configured: true,
      ipaAddress: 'mokoji@instapay',
      beneficiaryName: 'مكوجي',
    ),
    List<PaymentRecord>? pending,
  }) : pending = pending ?? [];

  InstapayDetails details;
  List<PaymentRecord> pending;
  final submitCalls = <({String orderId, double amount, String reference})>[];
  final verifyCalls = <({String paymentId, bool approve, String? reason})>[];
  Object? submitFailWith;

  @override
  Future<InstapayDetails> getInstapayDetails() async => details;

  @override
  Future<List<PaymentRecord>> getMyPayments() async => [];

  @override
  Future<String> uploadProof(Uint8List bytes, String ext) async =>
      'c1/uploaded.$ext';

  @override
  Future<String> signedProofUrl(String path) async =>
      'https://example.invalid/$path';

  @override
  Future<String> submitInstapayPayment({
    required String orderId,
    required double amount,
    required String reference,
    required String proofPath,
    required String clientRequestId,
  }) async {
    if (submitFailWith != null) throw submitFailWith!;
    submitCalls.add((orderId: orderId, amount: amount, reference: reference));
    return 'payment-1';
  }

  @override
  Future<List<PaymentRecord>> getPendingInstapaySubmissions() async => pending;

  @override
  Future<void> verifyInstapayPayment({
    required String paymentId,
    required bool approve,
    String? rejectionReason,
  }) async {
    verifyCalls.add((
      paymentId: paymentId,
      approve: approve,
      reason: rejectionReason,
    ));
    pending = pending.where((p) => p.id != paymentId).toList();
  }

  @override
  Future<void> setInstapaySettings({
    required String ipaAddress,
    required String beneficiaryName,
  }) async {
    details = InstapayDetails(
      configured: ipaAddress.isNotEmpty,
      ipaAddress: ipaAddress,
      beneficiaryName: beneficiaryName,
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required _FakePaymentRepo repo,
  Order? order,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
        if (order != null)
          orderDetailProvider('o1').overrideWith((ref) => Stream.value(order)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(textDirection: TextDirection.rtl, child: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The admin review card formats a date with Formatters.dateTime (ar
  // locale) — the first widget test in this project to render one, so the
  // intl locale data isn't loaded by anything else already.
  setUpAll(() => initializeDateFormatting('ar'));


  group('Payment models', () {
    test('PaymentRecord.fromRow parses channel/status/metadata, no cost column', () {
      final p = _payment('p1');
      expect(p.channel, PaymentChannel.instapay);
      expect(p.status, PaymentTxnStatus.pendingVerification);
      expect(p.proofPath, 'c1/proof.jpg');
      expect(p.rejectionReason, isNull);
    });

    test('unknown enum strings fall back safely', () {
      expect(paymentChannelFromString('bogus'), PaymentChannel.cashOnDelivery);
      expect(paymentTxnStatusFromString('bogus'), PaymentTxnStatus.pending);
    });

    test('InstapayDetails.fromRpc', () {
      final d = InstapayDetails.fromRpc({'configured': false});
      expect(d.configured, isFalse);
      expect(d.ipaAddress, isNull);
    });
  });

  group('InstapayPaymentScreen', () {
    testWidgets('shows "not configured" when the admin has not set a handle', (
      tester,
    ) async {
      final repo = _FakePaymentRepo(
        details: const InstapayDetails(configured: false),
      );
      await _pump(
        tester,
        const InstapayPaymentScreen(orderId: 'o1'),
        repo: repo,
        order: _order(),
      );
      expect(find.textContaining('مش متاح دلوقتي'), findsOneWidget);
    });

    testWidgets('shows the handle and pre-fills the remaining amount', (
      tester,
    ) async {
      final repo = _FakePaymentRepo();
      await _pump(
        tester,
        const InstapayPaymentScreen(orderId: 'o1'),
        repo: repo,
        order: _order(remaining: 250),
      );
      expect(find.text('mokoji@instapay'), findsOneWidget);
      expect(find.textContaining('مكوجي'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('validates reference and proof before submitting', (
      tester,
    ) async {
      final repo = _FakePaymentRepo();
      await _pump(
        tester,
        const InstapayPaymentScreen(orderId: 'o1'),
        repo: repo,
        order: _order(),
      );
      await tester.tap(find.byKey(const Key('submit-instapay')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب رقم أو مرجع العملية من تطبيق InstaPay'), findsOneWidget);
      expect(repo.submitCalls, isEmpty);
    });
  });

  group('AdminInstapayReviewScreen', () {
    testWidgets('empty state when nothing is pending', (tester) async {
      final repo = _FakePaymentRepo(pending: []);
      await _pump(
        tester,
        const AdminInstapayReviewScreen(),
        repo: repo,
      );
      expect(find.text('لا توجد تحويلات بانتظار المراجعة'), findsOneWidget);
    });

    testWidgets('lists a submission and approves it', (tester) async {
      final repo = _FakePaymentRepo(pending: [_payment('p1', amount: 150)]);
      await _pump(tester, const AdminInstapayReviewScreen(), repo: repo);
      expect(find.text('REF-1'), findsNothing); // reference is prefixed
      expect(find.textContaining('REF-1'), findsOneWidget);

      await tester.tap(find.text('تأكيد الدفع'));
      await tester.pumpAndSettle();
      expect(repo.verifyCalls, hasLength(1));
      expect(repo.verifyCalls.single.approve, isTrue);
      expect(find.text('لا توجد تحويلات بانتظار المراجعة'), findsOneWidget);
    });

    testWidgets('rejecting asks for a reason first', (tester) async {
      final repo = _FakePaymentRepo(pending: [_payment('p1')]);
      await _pump(tester, const AdminInstapayReviewScreen(), repo: repo);

      await tester.tap(find.text('رفض'));
      await tester.pumpAndSettle();
      expect(find.text('سبب الرفض'), findsOneWidget);

      // Cancelling makes no call.
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(repo.verifyCalls, isEmpty);

      await tester.tap(find.text('رفض').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'المرجع غير صحيح');
      await tester.tap(find.text('رفض').last);
      await tester.pumpAndSettle();

      expect(repo.verifyCalls.single.approve, isFalse);
      expect(repo.verifyCalls.single.reason, 'المرجع غير صحيح');
    });
  });
}
