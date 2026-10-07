import 'package:flutter/material.dart';

/// Customer name + phone, both optional — the first thing filled in at the
/// counter, so it sits above everything else.
class WalkInCustomerHeader extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  const WalkInCustomerHeader({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      // Side by side these two labels get ellipsised on a phone — the admin
      // shell's rail leaves the content barely 260 logical pixels wide — so
      // they stack until there is room for both.
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 420
            ? Column(children: [name, const SizedBox(height: 8), phone])
            : Row(
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 12),
                  Expanded(child: phone),
                ],
              ),
      ),
    );
  }
}
