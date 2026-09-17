import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/wallet/data/models/wallet_models.dart';
import 'package:steam_gallery_app/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:steam_gallery_app/features/wallet/presentation/screens/admin/admin_wallets_list_screen.dart';

WalletSummary _summary(String name, double balance) => WalletSummary.fromRow({
  'wallet_id': 'w-$name',
  'customer_id': 'c-$name',
  'customer_name': name,
  'balance': balance,
  'currency': 'EGP',
  'is_active': true,
});

Future<void> _pump(
  WidgetTester tester,
  List<WalletSummary> wallets, {
  double totalLiability = 0,
  int walletCount = 0,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminWalletsProvider(search: null).overrideWith((ref) async => wallets),
        walletLiabilityProvider.overrideWith(
          (ref) async =>
              (totalLiability: totalLiability, walletCount: walletCount),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: AdminWalletsListScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminWalletsListScreen (Phase 15)', () {
    testWidgets('shows the total liability and every customer wallet', (
      tester,
    ) async {
      await _pump(
        tester,
        [_summary('أحمد', 300), _summary('سارة', 150)],
        totalLiability: 450,
        walletCount: 2,
      );
      expect(find.textContaining(Formatters.currency(450)), findsWidgets);
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('سارة'), findsOneWidget);
    });

    testWidgets('shows an empty state with no wallets', (tester) async {
      await _pump(tester, []);
      expect(find.text('لا توجد محافظ بعد'), findsOneWidget);
    });
  });
}
