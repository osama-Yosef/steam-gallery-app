import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../maintenance/data/models/technician_option.dart';

/// The top of the register, filled in first: where the goods come from
/// (the main warehouse or a technician's bag) and who is buying — a
/// registered customer (needed to sell on credit, 0084), picked or added on
/// the spot, or just a name and phone, both optional.
class WalkInCustomerHeader extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;

  /// Technicians whose bag can be sold from; empty hides the choice.
  final List<TechnicianOption> technicians;

  /// The bag being sold from; null = the main warehouse.
  final String? technicianId;
  final ValueChanged<String?> onSourceChanged;

  /// The registered customer picked for this sale, if any.
  final String? customerName;
  final VoidCallback onPickCustomer;
  final VoidCallback onNewCustomer;
  final VoidCallback onClearCustomer;

  const WalkInCustomerHeader({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    this.technicians = const [],
    this.technicianId,
    required this.onSourceChanged,
    this.customerName,
    required this.onPickCustomer,
    required this.onNewCustomer,
    required this.onClearCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final source = DropdownButtonFormField<String?>(
      // Re-keyed so a reset after a sale shows the warehouse again.
      key: ValueKey('source-$technicianId'),
      initialValue: technicianId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'البيع من',
        prefixIcon: Icon(Iconsax.box_copy),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('المخزن الرئيسي')),
        for (final t in technicians)
          DropdownMenuItem(value: t.id, child: Text('شنطة ${t.fullName}')),
      ],
      onChanged: onSourceChanged,
    );

    final Widget who;
    if (customerName != null) {
      who = Align(
        alignment: AlignmentDirectional.centerStart,
        child: InputChip(
          avatar: const Icon(Iconsax.user_tick_copy, size: 18),
          label: Text(customerName!),
          onPressed: onPickCustomer,
          onDeleted: onClearCustomer,
          deleteButtonTooltipMessage: 'إلغاء اختيار العميل',
        ),
      );
    } else {
      final name = TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
          labelText: 'اسم العميل (اختياري)',
          isDense: true,
        ),
      );
      final phone = TextField(
        controller: phoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'رقم الهاتف (اختياري)',
          isDense: true,
        ),
      );
      final buttons = Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: onPickCustomer,
            icon: const Icon(Iconsax.people_copy, size: 18),
            label: const Text('عميل مسجل'),
          ),
          TextButton.icon(
            onPressed: onNewCustomer,
            icon: const Icon(Iconsax.user_add_copy, size: 18),
            label: const Text('عميل جديد'),
          ),
        ],
      );
      // Side by side these two labels get ellipsised on a phone — the admin
      // shell's rail leaves the content barely 260 logical pixels wide — so
      // they stack until there is room for both.
      who = LayoutBuilder(
        builder: (context, c) => c.maxWidth < 420
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  name,
                  const SizedBox(height: 8),
                  phone,
                  const SizedBox(height: 4),
                  buttons,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: name),
                      const SizedBox(width: 12),
                      Expanded(child: phone),
                    ],
                  ),
                  const SizedBox(height: 4),
                  buttons,
                ],
              ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (technicians.isNotEmpty) ...[source, const SizedBox(height: 8)],
          who,
        ],
      ),
    );
  }
}
