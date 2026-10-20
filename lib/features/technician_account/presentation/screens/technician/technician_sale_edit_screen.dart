import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/data/models/technician_bag_stock_item.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../../sales/data/models/invoice_line.dart';
import '../../../../sales/presentation/providers/sales_providers.dart';
import '../../../../sales/presentation/state/invoice_draft.dart';
import '../../../../sales/presentation/state/line_change.dart';
import '../../../../sales/presentation/widgets/invoice_editor/invoice_cards.dart';
import '../../../../sales/presentation/widgets/invoice_editor/invoice_item_picker.dart';
import '../../../../sales/presentation/widgets/walk_in/line_price_dialog.dart';
import '../../../data/models/sale.dart';
import '../../providers/technician_account_providers.dart';

/// A technician's invoice opened for editing — by the technician who made
/// it or by admin: change quantities and prices, add or remove an item,
/// change the discount, or delete it (0087). Stock comes out of and goes
/// back into the technician's bag; the difference is on his account (on
/// the customer's for a deferred sale).
///
/// The same editing rules ([InvoiceDraft]) and cards as the register's
/// invoice editor, with the bag standing in for the warehouse.
class TechnicianSaleEditScreen extends ConsumerStatefulWidget {
  final String saleId;
  const TechnicianSaleEditScreen({super.key, required this.saleId});

  @override
  ConsumerState<TechnicianSaleEditScreen> createState() =>
      _TechnicianSaleEditScreenState();
}

class _TechnicianSaleEditScreenState
    extends ConsumerState<TechnicianSaleEditScreen> {
  InvoiceDraft? _draft;
  final _discountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  InvoiceDraft _draftFor(Sale sale, List<InvoiceLine> serverLines) {
    final existing = _draft;
    if (existing != null) return existing;
    final draft = InvoiceDraft.open(sale, serverLines);
    _discountCtrl.text = Formatters.plain(draft.initialDiscount);
    return _draft = draft;
  }

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;

  /// The bag in the shape the draft and the picker read stock in.
  static List<WarehouseStockItem> _asStock(List<TechnicianBagStockItem> bag) =>
      [
        for (final b in bag)
          WarehouseStockItem(
            productId: b.productId,
            productName: b.productName,
            sku: b.sku,
            quantity: b.quantity,
            costPrice: b.costPrice,
            sellingPrice: b.sellingPrice,
            minStock: 0,
          ),
      ];

  void _changeQuantity(
    String productId,
    int delta,
    List<WarehouseStockItem> stock,
  ) {
    final change = _draft!.changeQuantity(productId, delta, stock);
    if (change == LineChange.overStock) _snack('المتاح في الشنطة لا يكفي');
    setState(() {});
  }

  Future<void> _addItem(List<WarehouseStockItem> stock) async {
    final services = await ref.read(serviceProductsProvider.future);
    if (!mounted) return;
    final line = await pickInvoiceItem(
      context,
      stock: stock,
      services: services,
    );
    if (line == null || !mounted) return;
    final change = _draft!.add(line, stock);
    if (change == LineChange.overStock) _snack('المتاح في الشنطة لا يكفي');
    setState(() {});
  }

  Future<void> _editPrice(
    InvoiceLine line,
    List<InvoiceLine> serverLines,
  ) async {
    final original = serverLines
        .where((l) => l.productId == line.productId)
        .firstOrNull;
    final price = await showPriceDialog(
      context,
      name: line.productName,
      price: line.unitPrice,
      listPrice: original?.unitPrice ?? line.unitPrice,
    );
    if (price == null || !mounted) return;
    setState(() => _draft!.setPrice(line.productId, price));
  }

  void _refresh(Sale sale) {
    ref.invalidate(technicianSaleDetailProvider(sale.id));
    ref.invalidate(saleItemsProvider(sale.id));
    ref.invalidate(invoiceLinesProvider(sale.id));
    final techId = sale.technicianId;
    if (techId != null) {
      ref.invalidate(technicianSalesProvider(techId));
      ref.invalidate(technicianBagStockProvider(techId));
      ref.invalidate(technicianAccountSummaryProvider(techId));
      ref.invalidate(technicianAccountTransactionsProvider(techId));
    }
  }

  String _moneyNote(Sale sale, double diff) {
    final amount = Formatters.currency(diff.abs());
    if (sale.paymentMethod == PaymentMethod.deferred) {
      return diff > 0
          ? 'هيتزود $amount على حساب العميل'
          : 'هيتشال $amount من حساب العميل';
    }
    return diff > 0
        ? 'هيتزود $amount على المطلوب توريده من الصنايعي'
        : 'هيقل $amount من المطلوب توريده من الصنايعي';
  }

  Future<void> _save(Sale sale) async {
    if (_saving) return;
    final draft = _draft!;
    final problem = draft.saveProblem(_discount);
    if (problem != null) {
      _snack(problem);
      return;
    }
    final newTotal = draft.total(_discount);
    final diff = newTotal - sale.total;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حفظ التعديل؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإجمالي قبل: ${Formatters.currency(sale.total)}'),
            Text('الإجمالي بعد: ${Formatters.currency(newTotal)}'),
            if (diff.abs() >= 0.005) ...[
              const SizedBox(height: 8),
              Text(_moneyNote(sale, diff)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _write(
      sale,
      () => ref
          .read(technicianAccountRepositoryProvider)
          .editSale(
            saleId: sale.id,
            items: draft.lines,
            discount: double.parse(_discount.toStringAsFixed(2)),
          ),
      doneMsg: 'تم حفظ تعديل الفاتورة',
    );
  }

  Future<void> _delete(Sale sale) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف فاتورة #${sale.saleNumber}؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'كل الأصناف هترجع الشنطة، والفلوس هتتشال من الحساب. '
              'الفاتورة هتفضل في السجل كـ "ملغي".',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'السبب (اختياري)',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true || !mounted) return;
    await _write(
      sale,
      () => ref
          .read(technicianAccountRepositoryProvider)
          .deleteSale(
            saleId: sale.id,
            reason: reason.isEmpty ? 'حذف فاتورة' : reason,
          ),
      doneMsg: 'تم حذف الفاتورة',
    );
  }

  Future<void> _write(
    Sale sale,
    Future<void> Function() write, {
    required String doneMsg,
  }) async {
    setState(() => _saving = true);
    try {
      await write();
      _refresh(sale);
      if (!mounted) return;
      _snack(doneMsg);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleAsync = ref.watch(technicianSaleDetailProvider(widget.saleId));
    final linesAsync = ref.watch(invoiceLinesProvider(widget.saleId));
    final sale = saleAsync.value;
    final serverLines = linesAsync.value;
    final bagAsync = sale?.technicianId == null
        ? null
        : ref.watch(technicianBagStockProvider(sale!.technicianId!));

    if (sale == null || serverLines == null || bagAsync?.value == null) {
      final failed =
          saleAsync.hasError ||
          linesAsync.hasError ||
          (bagAsync?.hasError ?? false) ||
          (saleAsync.hasValue && sale == null);
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل الفاتورة')),
        body: failed
            ? ErrorView(
                message: 'تعذَّر تحميل الفاتورة',
                onRetry: () {
                  ref.invalidate(technicianSaleDetailProvider(widget.saleId));
                  ref.invalidate(invoiceLinesProvider(widget.saleId));
                },
              )
            : const LoadingView(),
      );
    }

    final stock = _asStock(bagAsync!.value!);
    final editable = sale.status == SaleStatus.completed;
    final draft = _draftFor(sale, serverLines);
    final total = draft.total(_discount);

    return Scaffold(
      appBar: AppBar(
        title: Text('فاتورة #${sale.saleNumber}'),
        actions: [
          if (editable)
            IconButton(
              tooltip: 'حذف الفاتورة',
              icon: const Icon(Iconsax.trash_copy, color: AppColors.danger),
              onPressed: _saving ? null : () => _delete(sale),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InvoiceInfoCard(sale: sale, pendingDelete: false, fromPending: false),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الأصناف',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (editable)
                TextButton.icon(
                  onPressed: () => _addItem(stock),
                  icon: const Icon(Iconsax.add_copy),
                  label: const Text('إضافة صنف'),
                ),
            ],
          ),
          if (editable)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'اضغط على الصنف لتغيير سعره',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          InvoiceLinesCard(
            lines: draft.lines,
            editable: editable,
            onChangeQuantity: (id, delta) => _changeQuantity(id, delta, stock),
            onRemove: (id) => setState(() => draft.remove(id)),
            onEditPrice: (l) => _editPrice(l, serverLines),
          ),
          const SizedBox(height: 12),
          InvoiceTotalsCard(
            subtotal: draft.subtotal,
            discount: _discount,
            total: total,
            savedTotal: sale.total,
            editable: editable,
            discountCtrl: _discountCtrl,
            onDiscountChanged: () => setState(() {}),
          ),
        ],
      ),
      bottomNavigationBar: editable
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _save(sale),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.tick_circle_copy),
                  label: Text('حفظ التعديلات · ${Formatters.currency(total)}'),
                ),
              ),
            )
          : null,
    );
  }
}
