import 'package:flutter/material.dart';
import '../../../../core/widgets/money_text.dart';
import '../../data/models/technician_account_summary.dart';

class AccountSummaryCard extends StatelessWidget {
  final TechnicianAccountSummary summary;
  const AccountSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, 'قيمة البضاعة بالشنطة', summary.bagValue),
            const Divider(),
            _row(context, 'إجمالي المبيعات', summary.totalSales),
            const Divider(),
            _row(context, 'إجمالي التحصيل', summary.totalCollected),
            const Divider(),
            _row(context, 'المطلوب توريده', summary.amountDue, emphasize: true),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, double amount, {bool emphasize = false}) {
    final style = emphasize ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          MoneyText(amount, style: style),
        ],
      ),
    );
  }
}
