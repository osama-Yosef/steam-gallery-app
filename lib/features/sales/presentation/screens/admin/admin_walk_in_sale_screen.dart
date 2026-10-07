import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../providers/sales_providers.dart';
import '../../state/register_stock.dart';
import '../../state/walk_in_cart.dart';
import '../../widgets/walk_in/add_service_dialog.dart';
import '../../widgets/walk_in/register_product_grid.dart';
import '../../widgets/walk_in/walk_in_checkout_bar.dart';
import '../../widgets/walk_in/walk_in_customer_header.dart';
import '../../widgets/walk_in_invoices_list.dart';

/// Counter sale for a walk-in customer who came to the gallery in person and
/// has no app account — reachable from the admin home dashboard. Sells from
/// the main warehouse and always takes payment in full (no credit tracking
/// for walk-ins).
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
    super.dispose();
  }

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _cart.subtotal - _discount;

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _addProduct(WarehouseStockItem item) {
    final change = _cart.addProduct(item);
    if (change == CartChange.overStock) {
      _snack('المتاح بالمخزن ${item.quantity} فقط');
    }
    setState(() {});
  }

  void _changeQuantity(CartLine line, int delta) {
    final change = _cart.changeQuantity(line.productId, delta);
    if (change == CartChange.overStock) {
      _snack('المتاح بالمخزن ${line.available} فقط');
    }
    setState(() {});
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
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(salesRepositoryProvider)
          .recordWalkInSale(
            customerName: _optional(_customerNameCtrl),
            customerPhone: _optional(_customerPhoneCtrl),
            items: _cart.toSaleInputs(),
            paymentMethod: _paymentMethod,
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
              submitting: _submitting,
              onDiscountChanged: () => setState(() {}),
              onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
              onChangeQuantity: _changeQuantity,
              onSubmit: _submit,
            ),
    );
  }

  Widget _saleTab() {
    final stockAsync = ref.watch(warehouseStockProvider());
    // Assembly products are optional extras on the grid — a failure there
    // (e.g. an older database without 0075) mustn't block selling stock.
    final assemblies = ref.watch(assemblyStockProvider).value ?? const [];
    final outbox = ref.watch(outboxProvider);

    return Column(
      children: [
        WalkInCustomerHeader(
          nameCtrl: _customerNameCtrl,
          phoneCtrl: _customerPhoneCtrl,
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
              message: 'تعذَّر تحميل المخزن',
              onRetry: () => ref.invalidate(warehouseStockProvider),
            ),
            data: (warehouse) => ListenableBuilder(
              listenable: outbox,
              builder: (context, _) {
                final items = sellableMatching(
                  registerStock(
                    warehouse,
                    assemblies,
                    queuedSales: outbox.pendingOf('walk_in_sale'),
                  ),
                  _search,
                );
                if (items.isEmpty) {
                  return EmptyView(
                    message: _search.isEmpty
                        ? 'لا توجد منتجات متاحة بالمخزن'
                        : 'لا توجد نتائج لـ "$_search"',
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
