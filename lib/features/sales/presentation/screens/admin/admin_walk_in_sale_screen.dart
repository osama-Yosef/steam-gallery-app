import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/data/models/product.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../data/models/sale_line_input.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../providers/sales_providers.dart';

/// Digits and at most one decimal point — everything the money fields on this
/// screen accept.
final _moneyInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d*'),
);

class _SaleLine {
  final String productId;
  final String productName;

  /// For a service this is the price agreed with the customer for THIS sale,
  /// not a catalogue price.
  final double sellingPrice;
  final int available;
  final bool isService;
  int quantity;
  _SaleLine({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.available,
    required this.quantity,
    this.isService = false,
  });

  double get lineTotal => quantity * sellingPrice;

  /// Only a service carries an explicit price to the server; for a stock
  /// product the catalogue price is authoritative (see SaleLineInput).
  double? get unitPrice => isService ? sellingPrice : null;
}

/// Counter sale for a walk-in customer who came to the gallery in person and
/// has no app account — reachable from the admin home dashboard. Sells from
/// the main warehouse and always takes payment in full (no credit tracking
/// for walk-ins).
///
/// Laid out top-to-bottom the way the sale actually happens at the counter:
/// customer first, then search, then tap products to add them, and a single
/// bottom bar that shows what to charge and confirms. The old version made
/// every line a modal dialog with a dropdown, which was several taps per item
/// and hid the running total behind a scroll.
class AdminWalkInSaleScreen extends ConsumerStatefulWidget {
  const AdminWalkInSaleScreen({super.key});

  @override
  ConsumerState<AdminWalkInSaleScreen> createState() =>
      _AdminWalkInSaleScreenState();
}

class _AdminWalkInSaleScreenState extends ConsumerState<AdminWalkInSaleScreen> {
  final String _clientRequestId = const Uuid().v4();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final List<_SaleLine> _lines = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String _search = '';
  bool _submitting = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal - _discount;

  /// Tapping a product adds one of it; tapping again bumps the quantity, so
  /// selling three of the same thing is three taps and never a dialog.
  void _addOrIncrement(WarehouseStockItem item) {
    final existing = _lines.where((l) => l.productId == item.productId);
    setState(() {
      if (existing.isEmpty) {
        _lines.add(
          _SaleLine(
            productId: item.productId,
            productName: item.productName,
            sellingPrice: item.sellingPrice,
            available: item.quantity,
            quantity: 1,
          ),
        );
        return;
      }
      final line = existing.first;
      if (line.quantity >= item.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('المتاح بالمخزن ${item.quantity} فقط')),
        );
        return;
      }
      line.quantity += 1;
    });
  }

  void _changeQuantity(_SaleLine line, int delta) {
    setState(() {
      final next = line.quantity + delta;
      if (next <= 0) {
        _lines.remove(line);
      } else if (!line.isService && next > line.available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('المتاح بالمخزن ${line.available} فقط')),
        );
      } else {
        line.quantity = next;
      }
    });
  }

  /// Adds a labour line. Unlike a stock product the price isn't in the
  /// catalogue — it's agreed per job — so it's typed here and sent explicitly.
  Future<void> _addServiceLine() async {
    final services = await ref.read(serviceProductsProvider.future);
    if (!mounted) return;
    if (services.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد خدمات معرَّفة')));
      return;
    }
    Product selected = services.first;
    final priceCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة خدمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'الخدمة'),
                items: services
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (s) => setDialogState(() => selected = s!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_moneyInputFormatter],
                decoration: const InputDecoration(labelText: 'سعر الخدمة'),
              ),
            ],
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
      ),
    );
    if (added != true) return;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    if (price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('أدخل سعرًا صحيحًا')));
      }
      return;
    }
    setState(() {
      _lines.add(
        _SaleLine(
          productId: selected.id,
          productName: selected.name,
          sellingPrice: price,
          available: 1,
          quantity: 1,
          isService: true,
        ),
      );
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف منتجًا واحدًا على الأقل')),
      );
      return;
    }
    if (_total < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الخصم أكبر من إجمالي الفاتورة')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(salesRepositoryProvider)
          .recordWalkInSale(
            customerName: _customerNameCtrl.text.trim().isEmpty
                ? null
                : _customerNameCtrl.text.trim(),
            customerPhone: _customerPhoneCtrl.text.trim().isEmpty
                ? null
                : _customerPhoneCtrl.text.trim(),
            items: _lines
                .map(
                  (l) => SaleLineInput(
                    productId: l.productId,
                    quantity: l.quantity,
                    unitPrice: l.unitPrice,
                  ),
                )
                .toList(),
            paymentMethod: _paymentMethod,
            discount: _discount,
            clientRequestId: _clientRequestId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      ref.invalidate(warehouseStockProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تسجيل البيع بنجاح')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtering happens on the already-loaded list rather than re-querying per
    // keystroke: the warehouse is small and this keeps typing instant.
    final stockAsync = ref.watch(warehouseStockProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيع مباشر'),
        actions: [
          TextButton.icon(
            onPressed: _addServiceLine,
            icon: const Icon(Icons.handyman_outlined),
            label: const Text('خدمة'),
          ),
        ],
      ),
      body: Column(
        children: [
          _CustomerHeader(
            nameCtrl: _customerNameCtrl,
            phoneCtrl: _customerPhoneCtrl,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
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
              data: (stock) {
                final available = stock
                    .where((s) => s.quantity > 0)
                    .where(
                      (s) =>
                          _search.isEmpty ||
                          s.productName.toLowerCase().contains(
                            _search.toLowerCase(),
                          ) ||
                          s.sku.toLowerCase().contains(_search.toLowerCase()),
                    )
                    .toList();
                if (available.isEmpty) {
                  return EmptyView(
                    message: _search.isEmpty
                        ? 'لا توجد منتجات متاحة بالمخزن'
                        : 'لا توجد نتائج لـ "$_search"',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return LayoutBuilder(
                  builder: (context, c) {
                    final columns = (c.maxWidth / 180).floor().clamp(2, 6);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: available.length,
                      itemBuilder: (context, i) {
                        final item = available[i];
                        final line = _lines
                            .where((l) => l.productId == item.productId)
                            .firstOrNull;
                        return _ProductCard(
                          item: item,
                          inCart: line?.quantity ?? 0,
                          onTap: () => _addOrIncrement(item),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CheckoutBar(
        lines: _lines,
        subtotal: _subtotal,
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
}

/// Customer name + phone, both optional — the first thing filled in at the
/// counter, so it sits above everything else.
class _CustomerHeader extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  const _CustomerHeader({required this.nameCtrl, required this.phoneCtrl});

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

class _ProductCard extends StatelessWidget {
  final WarehouseStockItem item;
  final int inCart;
  final VoidCallback onTap;
  const _ProductCard({
    required this.item,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.imageUrl == null
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Formatters.currency(item.sellingPrice),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'متاح ${item.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Quantity already in the cart, so the same grid doubles as the
            // "what have I rung up so far" view without scrolling anywhere.
            if (inCart > 0)
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '$inCart',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The bottom bar: discount sits directly above the total/confirm button, and
/// the cart itself expands from here so the product grid never gets pushed
/// off screen.
class _CheckoutBar extends StatelessWidget {
  final List<_SaleLine> lines;
  final double subtotal;
  final double total;
  final TextEditingController discountCtrl;
  final TextEditingController notesCtrl;
  final PaymentMethod paymentMethod;
  final bool submitting;
  final VoidCallback onDiscountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final void Function(_SaleLine, int) onChangeQuantity;
  final VoidCallback onSubmit;

  const _CheckoutBar({
    required this.lines,
    required this.subtotal,
    required this.total,
    required this.discountCtrl,
    required this.notesCtrl,
    required this.paymentMethod,
    required this.submitting,
    required this.onDiscountChanged,
    required this.onPaymentMethodChanged,
    required this.onChangeQuantity,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCount = lines.fold<int>(0, (sum, l) => sum + l.quantity);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lines.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('السلة ($itemCount صنف)'),
                  subtitle: Text('المجموع ${Formatters.currency(subtotal)}'),
                  children: [
                    for (final line in lines)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(line.productName),
                        subtitle: Text(
                          '${line.quantity} × '
                          '${Formatters.currency(line.sellingPrice)}'
                          '${line.isService ? ' · خدمة' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => onChangeQuantity(line, -1),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => onChangeQuantity(line, 1),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // A hardware keyboard ignores keyboardType, so on
                      // desktop a stray letter used to sit in here silently
                      // parsing as 0 — found while testing the Windows build.
                      inputFormatters: [_moneyInputFormatter],
                      decoration: const InputDecoration(
                        labelText: 'الخصم',
                        isDense: true,
                      ),
                      onChanged: (_) => onDiscountChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PaymentMethod>(
                      initialValue: paymentMethod,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع',
                        isDense: true,
                      ),
                      items:
                          const [
                                PaymentMethod.cash,
                                PaymentMethod.card,
                                PaymentMethod.transfer,
                              ]
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(paymentMethodLabelAr(m)),
                                ),
                              )
                              .toList(),
                      onChanged: (m) => onPaymentMethodChanged(m!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting || lines.isEmpty ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.point_of_sale_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'تأكيد البيع · ${Formatters.currency(total)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
