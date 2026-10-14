import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../customer_account/data/models/customer_account_summary.dart';
import '../../../../customer_account/presentation/providers/customer_account_providers.dart';
import '../../../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../../../users_admin/presentation/providers/users_admin_providers.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../providers/sales_providers.dart';
import '../../state/register_stock.dart';
import '../../state/line_change.dart';
import '../../state/walk_in_cart.dart';
import '../../widgets/walk_in/add_service_dialog.dart';
import '../../widgets/walk_in/register_product_grid.dart';
import '../../widgets/walk_in/line_price_dialog.dart';
import '../../widgets/walk_in/walk_in_checkout_bar.dart';
import '../../widgets/walk_in/walk_in_customer_header.dart';
import '../../widgets/walk_in_invoices_list.dart';

/// Counter sale for a customer who came to the gallery in person — admin and
/// sales. Sells from the main warehouse or a technician's bag, paid in full
/// (نقدي), on credit (آجل) or part now (جزئي); credit goes on a registered
/// customer's account, picked or added right here (0084).
///
/// Laid out top-to-bottom the way the sale actually happens at the counter:
/// customer first, then search, then tap products to add them, and a single
/// bottom bar that shows what to charge and confirms.
///
/// A second tab lists every invoice (today's by default) for editing or
/// deleting; the dashboard's "مبيعات اليوم" tile opens straight onto it
/// ([showInvoices]). Works offline: a sale is queued and the stock shown
/// already accounts for queued sales.
///
/// The selling rules live in [WalkInCart]; the pieces of the screen in
/// `widgets/walk_in/`. This class wires them together and submits the sale.
class AdminWalkInSaleScreen extends ConsumerStatefulWidget {
  final bool showInvoices;
  const AdminWalkInSaleScreen({super.key, this.showInvoices = false});

  @override
  ConsumerState<AdminWalkInSaleScreen> createState() =>
      _AdminWalkInSaleScreenState();
}

class _AdminWalkInSaleScreenState extends ConsumerState<AdminWalkInSaleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.showInvoices ? 1 : 0,
  )..addListener(_onTabChanged);
  late int _tabIndex = _tabs.index;

  /// The controller also notifies on every frame of the swipe animation;
  /// rebuilding the whole register (grid included) for each of those made
  /// switching tabs stutter. Only an actual tab change matters here.
  void _onTabChanged() {
    if (_tabs.index != _tabIndex) setState(() => _tabIndex = _tabs.index);
  }

  // Not final: reached two ways — pushed from the admin dashboard (a fresh
  // screen, and so a fresh key, per sale) and as the sales role's bottom-nav
  // home tab, where IndexedStack keeps this same State alive across many
  // sales in a row. A key that never changed would make every sale after
  // the first in that tab reuse the first one's idempotency key.
  String _clientRequestId = const Uuid().v4();
  final _cart = WalkInCart();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _paidCtrl = TextEditingController();
  WalkInPayMode _payMode = WalkInPayMode.full;

  /// The bag being sold from; null = the main warehouse.
  String? _technicianId;

  /// The registered customer this sale is for, if any.
  ({String id, String name})? _customer;
  String _search = '';
  bool _submitting = false;

  @override
  void dispose() {
    _tabs.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _cart.subtotal - _discount;

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _addProduct(WarehouseStockItem item) {
    final change = _cart.addProduct(item);
    if (change == LineChange.overStock) {
      _snack('المتاح بالمخزن ${item.quantity} فقط');
    }
    setState(() {});
  }

  void _changeQuantity(CartLine line, int delta) {
    final change = _cart.changeQuantity(line.productId, delta);
    if (change == LineChange.overStock) {
      _snack('المتاح بالمخزن ${line.available} فقط');
    }
    setState(() {});
  }

  Future<void> _editPrice(CartLine line) async {
    final price = await showLinePriceDialog(context, line);
    if (price == null || !mounted) return;
    setState(() => _cart.setPrice(line, price));
  }

  Future<void> _addService() async {
    final services = await ref.read(serviceProductsProvider.future);
    if (!mounted) return;
    if (services.isEmpty) {
      _snack('لا توجد خدمات معرَّفة');
      return;
    }
    final picked = await showAddServiceDialog(context, services);
    if (picked == null || !mounted) return;
    if (picked.price <= 0) {
      _snack('أدخل سعرًا صحيحًا');
      return;
    }
    setState(() => _cart.addService(picked.service, picked.price));
  }

  /// The cart's lines came from the old place — they can't follow.
  void _changeSource(String? technicianId) {
    if (technicianId == _technicianId) return;
    if (!_cart.isEmpty) _snack('السلة اتفضت — المنتجات كانت من مكان تاني');
    setState(() {
      _technicianId = technicianId;
      _cart.clear();
    });
  }

  Future<void> _pickCustomer() async {
    final List<CustomerAccountSummary> customers;
    try {
      customers = await ref.read(customerAccountsProvider().future);
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
      return;
    }
    if (!mounted) return;
    final picked = await showSearchPickerSheet<CustomerAccountSummary>(
      context,
      title: 'اختيار عميل',
      items: customers,
      label: (c) => c.customerName,
      subtitle: (c) => c.remainingBalance > 0
          ? 'عليه ${Formatters.currency(c.remainingBalance)}'
          : 'مفيش عليه حاجة',
    );
    if (picked == null || !mounted) return;
    setState(
      () => _customer = (id: picked.customerId, name: picked.customerName),
    );
  }

  Future<void> _newCustomer() async {
    final created = await showDialog<({String id, String name})>(
      context: context,
      builder: (_) => const _NewCustomerDialog(),
    );
    if (created == null || !mounted) return;
    ref.invalidate(customerAccountsProvider);
    setState(() => _customer = created);
    _snack('اتسجل العميل ${created.name}');
  }

  String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (_submitting) return;
    if (_cart.isEmpty) {
      _snack('أضف منتجًا واحدًا على الأقل');
      return;
    }
    if (_total < 0) {
      _snack('الخصم أكبر من إجمالي الفاتورة');
      return;
    }
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    if (_payMode != WalkInPayMode.full && _customer == null) {
      _snack('اختار العميل اللي هيتسجل عليه الباقي');
      await _pickCustomer();
      return;
    }
    if (_payMode == WalkInPayMode.partial && (paid <= 0 || paid >= _total)) {
      _snack('المدفوع لازم يكون أكبر من صفر وأقل من الإجمالي');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(salesRepositoryProvider)
          .recordWalkInSale(
            customerName: _customer == null
                ? _optional(_customerNameCtrl)
                : null,
            customerPhone: _customer == null
                ? _optional(_customerPhoneCtrl)
                : null,
            items: _cart.toSaleInputs(pinPrices: _technicianId != null),
            paymentMethod: _payMode == WalkInPayMode.credit
                ? PaymentMethod.deferred
                : _paymentMethod,
            customerId: _customer?.id,
            paidAmount: _payMode == WalkInPayMode.partial ? paid : null,
            technicianId: _technicianId,
            discount: _discount,
            clientRequestId: _clientRequestId,
            notes: _optional(_notesCtrl),
          );
      if (!mounted) return;
      if (result.queued) {
        showSavedOfflineSnack(context, 'البيع اتسجل');
      } else {
        _snack('تم تسجيل البيع بنجاح');
      }
      // Pushed from the admin dashboard, this screen sits on top of it and
      // should pop back. Reached as the sales role's home tab, it IS the
      // screen — there's nothing above it to pop to, and forcing a pop
      // here crashed the shell's nested navigator right after the sale
      // had already gone through server-side. Reset in place instead so
      // the next walk-in sale starts clean either way.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        _resetForNextSale();
      }
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForNextSale() {
    setState(() {
      _cart.clear();
      _customerNameCtrl.clear();
      _customerPhoneCtrl.clear();
      _discountCtrl.text = '0';
      _notesCtrl.clear();
      _paymentMethod = PaymentMethod.cash;
      _payMode = WalkInPayMode.full;
      _paidCtrl.clear();
      _customer = null;
      _clientRequestId = const Uuid().v4();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSaleTab = _tabIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيع مباشر'),
        actions: [
          if (onSaleTab)
            TextButton.icon(
              onPressed: _addService,
              icon: const Icon(Iconsax.setting_2_copy),
              label: const Text('خدمة'),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Iconsax.shopping_cart_copy), text: 'بيع جديد'),
            Tab(icon: Icon(Iconsax.receipt_text_copy), text: 'الفواتير'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_saleTab(), const WalkInInvoicesList()],
      ),
      bottomNavigationBar: !onSaleTab
          ? null
          : WalkInCheckoutBar(
              cart: _cart,
              total: _total,
              discountCtrl: _discountCtrl,
              notesCtrl: _notesCtrl,
              paymentMethod: _paymentMethod,
              payMode: _payMode,
              paidCtrl: _paidCtrl,
              submitting: _submitting,
              onDiscountChanged: () => setState(() {}),
              onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
              onPayModeChanged: (m) => setState(() => _payMode = m),
              onPaidChanged: () => setState(() {}),
              onChangeQuantity: _changeQuantity,
              onEditPrice: _editPrice,
              onSubmit: _submit,
            ),
    );
  }

  Widget _saleTab() {
    final bagId = _technicianId;
    // A bag's stock, shown the same way as the warehouse's. Its catalogue
    // price is what the sale charges (toSaleInputs pins it).
    final stockAsync = bagId == null
        ? ref.watch(warehouseStockProvider())
        : ref
              .watch(technicianBagStockProvider(bagId))
              .whenData(
                (bag) => [
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
                ],
              );
    // Assembly products are optional extras on the grid — a failure there
    // (e.g. an older database without 0075) mustn't block selling stock.
    // They are built from warehouse parts, so never sold from a bag.
    final assemblies = bagId != null
        ? const <WarehouseStockItem>[]
        : ref.watch(assemblyStockProvider).value ?? const [];
    final outbox = ref.watch(outboxProvider);

    return Column(
      children: [
        WalkInCustomerHeader(
          nameCtrl: _customerNameCtrl,
          phoneCtrl: _customerPhoneCtrl,
          technicians:
              ref.watch(assignableTechniciansProvider).value ?? const [],
          technicianId: _technicianId,
          onSourceChanged: _changeSource,
          customerName: _customer?.name,
          onPickCustomer: _pickCustomer,
          onNewCustomer: _newCustomer,
          onClearCustomer: () => setState(() => _customer = null),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(Iconsax.search_normal_1_copy),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Iconsax.close_circle_copy),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
        ),
        Expanded(
          child: stockAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: bagId == null
                  ? 'تعذَّر تحميل المخزن'
                  : 'تعذَّر تحميل الشنطة',
              onRetry: () => bagId == null
                  ? ref.invalidate(warehouseStockProvider)
                  : ref.invalidate(technicianBagStockProvider(bagId)),
            ),
            data: (warehouse) => ListenableBuilder(
              listenable: outbox,
              builder: (context, _) {
                final items = sellableMatching(
                  registerStock(
                    warehouse,
                    assemblies,
                    queuedSales: outbox.pendingOf('walk_in_sale'),
                    technicianId: bagId,
                  ),
                  _search,
                );
                if (items.isEmpty) {
                  return EmptyView(
                    message: _search.isNotEmpty
                        ? 'لا توجد نتائج لـ "$_search"'
                        : bagId == null
                        ? 'لا توجد منتجات متاحة بالمخزن'
                        : 'الشنطة فاضية',
                    icon: Iconsax.box_copy,
                  );
                }
                return RegisterProductGrid(
                  items: items,
                  quantityInCart: _cart.quantityOf,
                  onTap: _addProduct,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Adds a customer account on the spot (name + phone) to sell to them on
/// credit; returns it, or null when cancelled.
class _NewCustomerDialog extends ConsumerStatefulWidget {
  const _NewCustomerDialog();

  @override
  ConsumerState<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends ConsumerState<_NewCustomerDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || !RegExp(r'^01\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'اكتب الاسم ورقم موبايل صحيح (01xxxxxxxxx)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(usersAdminRepositoryProvider)
          .createCustomer(localPhone: phone, fullName: name);
      if (mounted) Navigator.of(context).pop((id: id, name: name));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppException.from(e).messageAr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('عميل جديد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'الاسم'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الموبايل',
              hintText: '01xxxxxxxxx',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تسجيل'),
        ),
      ],
    );
  }
}
