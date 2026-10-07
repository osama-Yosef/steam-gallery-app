import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../cashbox/data/models/cashbox_balance.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/data/models/product.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../../data/models/invoice_line.dart';
import '../../providers/sales_providers.dart';
import '../../state/register_stock.dart';
import '../../../../../features/cashbox/presentation/widgets/cashbox_kind_selector.dart';
import '../../../../../core/widgets/amount_row.dart';
import '../../../../../core/utils/input_formatters.dart';

/// A walk-in invoice opened from the history: add a product, remove one,
/// change quantities or the discount, or delete the whole invoice. Saving
/// sends the invoice's final content (rpc_admin_edit_sale, 0075) — the
/// server restocks/takes stock and settles the money difference in one go.
class AdminSaleInvoiceScreen extends ConsumerStatefulWidget {
  final String saleId;
  const AdminSaleInvoiceScreen({super.key, required this.saleId});

  @override
  ConsumerState<AdminSaleInvoiceScreen> createState() =>
      _AdminSaleInvoiceScreenState();
}

/// A thing that can be added to the invoice from the picker.
class _Pickable {
  final String productId;
  final String name;
  final double price;
  final int available;
  final bool isService;
  final bool isAssembly;
  const _Pickable({
    required this.productId,
    required this.name,
    required this.price,
    required this.available,
    this.isService = false,
    this.isAssembly = false,
  });
}

class _AdminSaleInvoiceScreenState
    extends ConsumerState<AdminSaleInvoiceScreen> {
  List<InvoiceLine>? _lines;

  /// What each product had on the invoice when it was opened — that much is
  /// already out of the warehouse, so it can always be kept.
  final Map<String, int> _originalQty = {};
  final _discountCtrl = TextEditingController();
  bool _saving = false;
  bool _fromPending = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// Starts from the server's lines — or, if an edit of this invoice is still
  /// waiting in the offline queue, from that edit, so a second edit builds
  /// on the first instead of silently undoing it.
  void _prefill(Sale sale, List<InvoiceLine> serverLines) {
    if (_lines != null) return;
    for (final l in serverLines) {
      _originalQty[l.productId] = l.quantity;
    }
    final pendingEdits = ref
        .read(outboxProvider)
        .pendingOf('sale_edit', refId: sale.id);
    final meta = pendingEdits.isEmpty ? null : pendingEdits.last.meta;
    if (meta != null && meta['lines'] is List) {
      _fromPending = true;
      _lines = (meta['lines'] as List)
          .map((e) => InvoiceLine.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final d = (meta['discount'] as num?)?.toDouble() ?? sale.discount;
      _discountCtrl.text = d.toStringAsFixed(2);
    } else {
      _lines = [...serverLines];
      _discountCtrl.text = sale.discount.toStringAsFixed(2);
    }
  }

  double get _subtotal =>
      (_lines ?? const []).fold<double>(0, (s, l) => s + l.lineTotal);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal - _discount;

  int _maxFor(String productId, List<WarehouseStockItem> stock) {
    final inStock = stock
        .where((s) => s.productId == productId)
        .fold<int>(0, (s, i) => s + i.quantity);
    return (_originalQty[productId] ?? 0) + inStock;
  }

  void _changeQty(InvoiceLine line, int delta, List<WarehouseStockItem> stock) {
    final next = line.quantity + delta;
    if (next <= 0) {
      setState(() => _lines!.remove(line));
      return;
    }
    if (!line.isService && next > _maxFor(line.productId, stock)) {
      _snack('المتاح بالمخزن لا يكفي');
      return;
    }
    setState(() {
      final i = _lines!.indexOf(line);
      _lines![i] = line.copyWith(quantity: next);
    });
  }

  Future<void> _addItem(List<WarehouseStockItem> stock) async {
    final services = await ref.read(serviceProductsProvider.future);
    if (!mounted) return;
    final pickables = [
      for (final s in stock)
        _Pickable(
          productId: s.productId,
          name: s.productName,
          price: s.displayPrice,
          available: s.quantity,
          isAssembly: s.isAssembly,
        ),
      for (final Product s in services)
        _Pickable(
          productId: s.id,
          name: s.name,
          price: s.sellingPrice,
          available: 999,
          isService: true,
        ),
    ];
    final picked = await showSearchPickerSheet<_Pickable>(
      context,
      title: 'إضافة صنف للفاتورة',
      items: pickables,
      label: (p) => p.name,
      subtitle: (p) => p.isService
          ? 'خدمة'
          : '${Formatters.currency(p.price)} · متاح ${p.available}'
                '${p.isAssembly ? ' · صنف تجميع' : ''}',
      enabled: (p) => p.isService || p.available > 0,
    );
    if (picked == null || !mounted) return;

    var price = picked.price;
    if (picked.isService) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(picked.name),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [moneyInputFormatter],
            decoration: const InputDecoration(labelText: 'سعر الخدمة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إضافة'),
            ),
          ],
        ),
      );
      price = double.tryParse(ctrl.text) ?? 0;
      if (ok != true) return;
      if (price <= 0) {
        _snack('أدخل سعرًا صحيحًا');
        return;
      }
    }

    final existing = _lines!.where((l) => l.productId == picked.productId);
    if (existing.isNotEmpty) {
      _changeQty(existing.first, 1, stock);
      return;
    }
    setState(() {
      _lines!.add(
        InvoiceLine(
          productId: picked.productId,
          productName: picked.name,
          quantity: 1,
          unitPrice: price,
          isService: picked.isService,
          isAssembly: picked.isAssembly,
        ),
      );
    });
  }

  CashboxKind _defaultKind(Sale sale) =>
      sale.paymentMethod == PaymentMethod.cash
      ? CashboxKind.cash
      : CashboxKind.transfer;

  Future<void> _save(Sale sale) async {
    if (_saving) return;
    if (_lines!.isEmpty) {
      _snack('الفاتورة فاضية — لو عايز تلغيها استخدم "حذف الفاتورة"');
      return;
    }
    if (_discount < 0 || _discount > _subtotal) {
      _snack('قيمة الخصم غير صحيحة');
      return;
    }
    final diff = _total - sale.total;
    var kind = _defaultKind(sale);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('حفظ التعديلات'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الإجمالي القديم: ${Formatters.currency(sale.total)}'),
              Text('الإجمالي الجديد: ${Formatters.currency(_total)}'),
              const SizedBox(height: 8),
              Text(
                diff.abs() < 0.005
                    ? 'لا يوجد فرق في الفلوس'
                    : diff > 0
                    ? 'هيتم تحصيل ${Formatters.currency(diff)} من العميل'
                    : 'هيتم رد ${Formatters.currency(-diff)} للعميل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: diff < 0 ? AppColors.danger : AppColors.success,
                ),
              ),
              if (diff.abs() >= 0.005) ...[
                const SizedBox(height: 12),
                CashboxKindSelector(
                  value: kind,
                  onChanged: (k) => setDialog(() => kind = k),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(salesRepositoryProvider)
          .editSale(
            saleId: sale.id,
            saleNumber: sale.saleNumber,
            items: _lines!,
            discount: double.parse(_discount.toStringAsFixed(2)),
            moneyKind: kind,
          );
      _afterWrite(result, 'التعديل اتسجل', 'تم حفظ تعديل الفاتورة');
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Sale sale) async {
    final reasonCtrl = TextEditingController();
    var kind = _defaultKind(sale);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('حذف فاتورة #${sale.saleNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'كل الأصناف هترجع المخزن، وهيتم رد ${Formatters.currency(sale.total)} للعميل.',
              ),
              const SizedBox(height: 12),
              if (sale.total > 0)
                CashboxKindSelector(
                  value: kind,
                  onChanged: (k) => setDialog(() => kind = k),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'السبب'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final reason = reasonCtrl.text.trim();
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(salesRepositoryProvider)
          .deleteSale(
            saleId: sale.id,
            saleNumber: sale.saleNumber,
            reason: reason.isEmpty ? 'حذف فاتورة' : reason,
            refundKind: kind,
          );
      _afterWrite(result, 'الحذف اتسجل', 'تم حذف الفاتورة');
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _afterWrite(OutboxResult result, String queuedMsg, String doneMsg) {
    if (!mounted) return;
    if (result.queued) {
      showSavedOfflineSnack(context, queuedMsg);
    } else {
      _snack(doneMsg);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(walkInSalesProvider);
    final linesAsync = ref.watch(invoiceLinesProvider(widget.saleId));
    final warehouse = ref.watch(warehouseStockProvider()).value ?? const [];
    final assemblies = ref.watch(assemblyStockProvider).value ?? const [];

    final sale = salesAsync.value
        ?.where((s) => s.id == widget.saleId)
        .firstOrNull;
    if (sale == null || linesAsync.value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الفاتورة')),
        body: salesAsync.hasError || linesAsync.hasError
            ? ErrorView(
                message: 'تعذَّر تحميل الفاتورة',
                onRetry: () {
                  ref.invalidate(walkInSalesProvider);
                  ref.invalidate(invoiceLinesProvider(widget.saleId));
                },
              )
            : const LoadingView(),
      );
    }

    final outbox = ref.watch(outboxProvider);
    return ListenableBuilder(
      listenable: outbox,
      builder: (context, _) {
        final stock = registerStock(
          warehouse,
          assemblies,
          queuedSales: outbox.pendingOf('walk_in_sale'),
        );
        final pendingDelete = outbox
            .pendingOf('sale_delete', refId: sale.id)
            .isNotEmpty;
        final editable = sale.status == SaleStatus.completed && !pendingDelete;
        _prefill(sale, linesAsync.value!);
        final lines = _lines!;
        final theme = Theme.of(context);

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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Formatters.dateTime(sale.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (sale.customerName != null)
                        Text('العميل: ${sale.customerName}'),
                      if (sale.customerPhone != null)
                        Text('التليفون: ${sale.customerPhone}'),
                      Text(
                        'الدفع: ${paymentMethodLabelAr(sale.paymentMethod)}',
                      ),
                      Text(
                        'الحالة: ${saleStatusLabelAr(sale.status)}',
                        style: TextStyle(
                          color: sale.status == SaleStatus.completed
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      if (pendingDelete)
                        const Text(
                          'الفاتورة هتتحذف أول ما النت يرجع',
                          style: TextStyle(color: AppColors.warning),
                        )
                      else if (_fromPending)
                        const Text(
                          'بتعدل على آخر تعديل لسه مستني المزامنة',
                          style: TextStyle(color: AppColors.warning),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('الأصناف', style: theme.textTheme.titleMedium),
                  ),
                  if (editable)
                    TextButton.icon(
                      onPressed: () => _addItem(stock),
                      icon: const Icon(Iconsax.add_copy),
                      label: const Text('إضافة صنف'),
                    ),
                ],
              ),
              Card(
                child: lines.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('لا توجد أصناف')),
                      )
                    : Column(
                        children: [
                          for (final l in lines)
                            ListTile(
                              title: Text(l.productName),
                              subtitle: Text(
                                '${Formatters.currency(l.unitPrice)}'
                                '${l.isService ? ' · خدمة' : ''}'
                                '${l.isAssembly ? ' · صنف تجميع' : ''}'
                                '  =  ${Formatters.currency(l.lineTotal)}',
                              ),
                              trailing: editable
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Iconsax.minus_cirlce_copy,
                                          ),
                                          onPressed: () =>
                                              _changeQty(l, -1, stock),
                                        ),
                                        Text(
                                          '${l.quantity}',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Iconsax.add_circle_copy,
                                          ),
                                          onPressed: () =>
                                              _changeQty(l, 1, stock),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف الصنف',
                                          icon: const Icon(
                                            Iconsax.trash_copy,
                                            color: AppColors.danger,
                                          ),
                                          onPressed: () =>
                                              setState(() => lines.remove(l)),
                                        ),
                                      ],
                                    )
                                  : Text('× ${l.quantity}'),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AmountRow('المجموع', _subtotal),
                      if (editable)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextField(
                            controller: _discountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [moneyInputFormatter],
                            decoration: const InputDecoration(
                              labelText: 'الخصم',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        )
                      else
                        AmountRow('الخصم', _discount),
                      AmountRow('الإجمالي', _total, bold: true),
                      if (editable && (_total - sale.total).abs() >= 0.005)
                        Text(
                          (_total - sale.total) > 0
                              ? 'فرق مطلوب من العميل: ${Formatters.currency(_total - sale.total)}'
                              : 'فرق يُرد للعميل: ${Formatters.currency(sale.total - _total)}',
                          style: TextStyle(
                            color: (_total - sale.total) > 0
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
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
                      label: Text(
                        'حفظ التعديلات · ${Formatters.currency(_total)}',
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
