import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../../data/models/invoice_line.dart';
import '../../providers/sales_providers.dart';
import '../../state/invoice_draft.dart';
import '../../state/line_change.dart';
import '../../state/register_stock.dart';
import '../../widgets/invoice_editor/invoice_cards.dart';
import '../../widgets/invoice_editor/invoice_dialogs.dart';
import '../../widgets/invoice_editor/invoice_item_picker.dart';

/// A walk-in invoice opened from the history: add a product, remove one,
/// change quantities or the discount, or delete the whole invoice. Saving
/// sends the invoice's final content (rpc_admin_edit_sale, 0075) — the
/// server restocks/takes stock and settles the money difference in one go.
///
/// The editing rules live in [InvoiceDraft]; the cards and dialogs in
/// `widgets/invoice_editor/`. This class wires them together and saves.
class AdminSaleInvoiceScreen extends ConsumerStatefulWidget {
  final String saleId;
  const AdminSaleInvoiceScreen({super.key, required this.saleId});

  @override
  ConsumerState<AdminSaleInvoiceScreen> createState() =>
      _AdminSaleInvoiceScreenState();
}

class _AdminSaleInvoiceScreenState
    extends ConsumerState<AdminSaleInvoiceScreen> {
  /// Created once, when the invoice first loads — later refetches must not
  /// wipe out what the admin is in the middle of changing.
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
    final draft = InvoiceDraft.open(
      sale,
      serverLines,
      pendingEdits: ref
          .read(outboxProvider)
          .pendingOf('sale_edit', refId: sale.id),
    );
    _discountCtrl.text = draft.initialDiscount.toStringAsFixed(2);
    return _draft = draft;
  }

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;

  void _changeQuantity(
    String productId,
    int delta,
    List<WarehouseStockItem> stock,
  ) {
    final change = _draft!.changeQuantity(productId, delta, stock);
    if (change == LineChange.overStock) _snack('المتاح بالمخزن لا يكفي');
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
    if (change == LineChange.overStock) _snack('المتاح بالمخزن لا يكفي');
    setState(() {});
  }

  Future<void> _save(Sale sale) async {
    if (_saving) return;
    final draft = _draft!;
    final problem = draft.saveProblem(_discount);
    if (problem != null) {
      _snack(problem);
      return;
    }
    final kind = await confirmInvoiceSave(
      context,
      oldTotal: sale.total,
      newTotal: draft.total(_discount),
      defaultKind: defaultTillFor(sale),
    );
    if (kind == null || !mounted) return;

    await _write(
      () => ref
          .read(salesRepositoryProvider)
          .editSale(
            saleId: sale.id,
            saleNumber: sale.saleNumber,
            items: draft.lines,
            discount: double.parse(_discount.toStringAsFixed(2)),
            moneyKind: kind,
          ),
      queuedMsg: 'التعديل اتسجل',
      doneMsg: 'تم حفظ تعديل الفاتورة',
    );
  }

  Future<void> _delete(Sale sale) async {
    final answer = await confirmInvoiceDelete(
      context,
      sale: sale,
      defaultKind: defaultTillFor(sale),
    );
    if (answer == null || !mounted) return;
    await _write(
      () => ref
          .read(salesRepositoryProvider)
          .deleteSale(
            saleId: sale.id,
            saleNumber: sale.saleNumber,
            reason: answer.reason.isEmpty ? 'حذف فاتورة' : answer.reason,
            refundKind: answer.kind,
          ),
      queuedMsg: 'الحذف اتسجل',
      doneMsg: 'تم حذف الفاتورة',
    );
  }

  /// Runs a save/delete, reports how it went, and closes the editor once it
  /// went through (or was queued offline).
  Future<void> _write(
    Future<OutboxResult> Function() write, {
    required String queuedMsg,
    required String doneMsg,
  }) async {
    setState(() => _saving = true);
    try {
      final result = await write();
      if (!mounted) return;
      if (result.queued) {
        showSavedOfflineSnack(context, queuedMsg);
      } else {
        _snack(doneMsg);
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final serverLines = linesAsync.value;
    if (sale == null || serverLines == null) {
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
              InvoiceInfoCard(
                sale: sale,
                pendingDelete: pendingDelete,
                fromPending: draft.fromPending,
              ),
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
              InvoiceLinesCard(
                lines: draft.lines,
                editable: editable,
                onChangeQuantity: (id, delta) =>
                    _changeQuantity(id, delta, stock),
                onRemove: (id) => setState(() => draft.remove(id)),
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
                      label: Text(
                        'حفظ التعديلات · ${Formatters.currency(total)}',
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
