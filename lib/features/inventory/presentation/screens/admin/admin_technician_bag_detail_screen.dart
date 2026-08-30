import 'package:flutter/material.dart';
import '../../widgets/bag_stock_body.dart';

class AdminTechnicianBagDetailScreen extends StatelessWidget {
  final String technicianId;
  const AdminTechnicianBagDetailScreen({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شنطة الصنايعي')),
      body: BagStockBody(technicianId: technicianId),
    );
  }
}
