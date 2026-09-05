import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../products/data/models/product.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../providers/inventory_providers.dart';

class AdminReceivePurchaseScreen extends ConsumerStatefulWidget {
  const AdminReceivePurchaseScreen({super.key});

  @override
  ConsumerState<AdminReceivePurchaseScreen> createState() =>
      _AdminReceivePurchaseScreenState();
}

class _AdminReceivePurchaseScreenState
    extends ConsumerState<AdminReceivePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Product? _selectedProduct;
  bool _submitting = false;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _unitCostCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('اختر المنتج أولًا')));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .receivePurchase(
            productId: _selectedProduct!.id,
            quantity: int.parse(_quantityCtrl.text),
            unitCost: double.parse(_unitCostCtrl.text),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
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
    final productsAsync = ref.watch(adminProductsProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('استلام بضاعة')),
      body: productsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل المنتجات'),
        data: (products) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Product>(
                  initialValue: _selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'المنتج'),
                  items: products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (${p.sku})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (p) => setState(() {
                    _selectedProduct = p;
                    _unitCostCtrl.text = p?.costPrice.toStringAsFixed(2) ?? '';
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'أدخل كمية صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'تكلفة الوحدة'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0) return 'أدخل تكلفة صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('تسجيل الاستلام'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
