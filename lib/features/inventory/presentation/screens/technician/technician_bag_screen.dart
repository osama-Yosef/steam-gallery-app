import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../widgets/bag_stock_body.dart';

class TechnicianBagScreen extends ConsumerWidget {
  const TechnicianBagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('شنطتي')),
      body: profile == null ? const SizedBox.shrink() : BagStockBody(technicianId: profile.id),
    );
  }
}
