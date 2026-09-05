import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/bag_stock_body.dart';

class AdminTechnicianBagDetailScreen extends StatelessWidget {
  final String technicianId;
  const AdminTechnicianBagDetailScreen({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شنطة الصنايعي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'الحساب',
            onPressed: () =>
                context.push(Routes.adminTechnicianAccount(technicianId)),
          ),
        ],
        bottom: BagValueAppBarBottom(technicianId: technicianId),
      ),
      body: BagStockBody(technicianId: technicianId),
    );
  }
}
