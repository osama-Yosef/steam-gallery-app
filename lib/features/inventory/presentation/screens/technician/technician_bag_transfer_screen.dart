import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/network_status.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../providers/inventory_providers.dart';

/// "تحويل": the technician moves stock himself between the main warehouse
/// and his own bag, either way, at once (0094). Needs a connection, like
/// selling from the bag.
class TechnicianBagTransferScreen extends ConsumerStatefulWidget {
  const TechnicianBagTransferScreen({super.key});

  @override
  ConsumerState<TechnicianBagTransferScreen> createState() =>
      _TechnicianBagTransferScreenState();
}

class _TechnicianBagTransferScreenState
    extends ConsumerState<TechnicianBagTransferScreen> {
  var _direction = BagTransferDirection.toBag;
  Future<List<BagTransferStock>>? _source;
  final _qty = <String, int>{};
  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _search = '';
  bool _submitting = false;

  /// One id per attempt at the same transfer: a retry after a lost response
  /// is then a no-op on the server. A new one once anything changes.
  String _requestId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? get _technicianId => ref.read(currentUserProfileProvider).value?.id;

  void _load() {
    final repo = ref.read(inventoryRepositoryProvider);
    final technicianId = _technicianId;
    _source = switch (_direction) {
      BagTransferDirection.toBag => repo.getWarehouseStockForTechnician(),
      BagTransferDirection.toWarehouse =>
        technicianId == null
            ? Future.value(const <BagTransferStock>[])
            : repo
                  .getBagStock(technicianId)
                  .then(
                    (bag) => [
                      for (final b in bag)
                        (
                          productId: b.productId,
                          productName: b.productName,
                          sku: b.sku,
                          quantity: b.quantity,
                        ),
                    ],
                  ),
    };
  }

  void _setDirection(BagTransferDirection d) {
    if (d == _direction) return;
    setState(() {
      _direction = d;
      _qty.clear();
      _requestId = const Uuid().v4();
      _load();
    });
  }

  void _setQty(BagTransferStock item, int qty) {
    setState(() {
      final q = qty.clamp(0, item.quantity);
      if (q == 0) {
        _qty.remove(item.productId);
      } else {
        _qty[item.productId] = q;
      }
      _requestId = const Uuid().v4();
    });
  }

  Future<void> _typeQty(BagTransferStock item) async {
    final ctrl = TextEditingController(text: '${_qty[item.productId] ?? 0}');
    final typed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.productName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'الكمية',
            helperText: 'المتاح: ${item.quantity}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(int.tryParse(ctrl.text)),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (typed != null) _setQty(item, typed);
  }

  Future<void> _submit(List<BagTransferStock> source) async {
    final lines = [
      for (final s in source)
        if ((_qty[s.productId] ?? 0) > 0) (item: s, qty: _qty[s.productId]!),
    ];
    if (lines.isEmpty) return;
    if (!NetworkStatus.instance.isOnline) {
      _say('التحويل محتاج نت');
      return;
    }
    final toBag = _direction == BagTransferDirection.toBag;
    final confirmed = await showConfirmDialog(
      context,
      title: toBag ? 'تحويل من المخزن لشنطتك' : 'ترجيع من شنطتك للمخزن',
      message: [
        for (final l in lines) '• ${l.item.productName}: ${l.qty}',
      ].join('\n'),
      confirmLabel: 'حوّل',
    );
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .transferBagStock(
            direction: _direction,
            items: [
              for (final l in lines)
                (productId: l.item.productId, quantity: l.qty),
            ],
            clientRequestId: _requestId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      final technicianId = _technicianId;
      if (technicianId != null) {
        ref.invalidate(technicianBagStockProvider(technicianId));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toBag ? 'اتحوّل لشنطتك' : 'اترجّع للمخزن')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _say(AppException.from(e).messageAr);
      // The source may have changed under us (another technician took it):
      // show the current quantities.
      if (mounted) setState(_load);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final toBag = _direction == BagTransferDirection.toBag;
    return Scaffold(
      appBar: AppBar(title: const Text('تحويل بضاعة')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<BagTransferDirection>(
                segments: const [
                  ButtonSegment(
                    value: BagTransferDirection.toBag,
                    icon: Icon(Iconsax.import_copy),
                    label: Text('من المخزن لشنطتي'),
                  ),
                  ButtonSegment(
                    value: BagTransferDirection.toWarehouse,
                    icon: Icon(Iconsax.export_copy),
                    label: Text('من شنطتي للمخزن'),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: _submitting
                    ? null
                    : (s) => _setDirection(s.first),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.search_normal_copy),
                hintText: 'دوّر على صنف',
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BagTransferStock>>(
              future: _source,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: AppException.from(snap.error!).messageAr,
                    onRetry: () => setState(_load),
                  );
                }
                final source = snap.data!;
                final shown = _search.isEmpty
                    ? source
                    : source
                          .where(
                            (s) =>
                                s.productName.contains(_search) ||
                                s.sku.toLowerCase().contains(
                                  _search.toLowerCase(),
                                ),
                          )
                          .toList();
                final picked = source
                    .where((s) => (_qty[s.productId] ?? 0) > 0)
                    .length;
                return Column(
                  children: [
                    Expanded(
                      child: source.isEmpty
                          ? EmptyView(
                              message: toBag
                                  ? 'مفيش بضاعة في المخزن'
                                  : 'شنطتك فاضية',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: shown.length,
                              itemBuilder: (_, i) => _Line(
                                item: shown[i],
                                qty: _qty[shown[i].productId] ?? 0,
                                enabled: !_submitting,
                                onChanged: (q) => _setQty(shown[i], q),
                                onTapQty: () => _typeQty(shown[i]),
                              ),
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _notesCtrl,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات (اختياري)',
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: picked == 0 || _submitting
                                    ? null
                                    : () => _submit(source),
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Iconsax.arrow_swap_copy),
                                label: Text(
                                  picked == 0
                                      ? 'اختار الأصناف والكميات'
                                      : 'تحويل $picked صنف',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.item,
    required this.qty,
    required this.enabled,
    required this.onChanged,
    required this.onTapQty,
  });

  final BagTransferStock item;
  final int qty;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapQty;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.productName),
      subtitle: Text('المتاح: ${item.quantity}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'أقل',
            icon: const Icon(Iconsax.minus_square_copy),
            onPressed: enabled && qty > 0 ? () => onChanged(qty - 1) : null,
          ),
          InkWell(
            onTap: enabled ? onTapQty : null,
            child: SizedBox(
              width: 36,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'أكتر',
            icon: const Icon(Iconsax.add_square_copy),
            onPressed: enabled && qty < item.quantity
                ? () => onChanged(qty + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
