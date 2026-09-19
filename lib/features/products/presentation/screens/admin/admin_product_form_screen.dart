import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_category.dart';
import '../../../data/models/product_image.dart';
import '../../../data/models/product_option.dart';
import '../../../presentation/providers/product_providers.dart';

/// One editable row in the "الخيارات الإضافية" section. [id] null means the
/// row is new and hasn't been saved yet.
class _OptionRow {
  String? id;
  String name;
  String priceText;
  _OptionRow({this.id, this.name = '', this.priceText = ''});
}

/// Create when [productId] is null, edit otherwise. Image management is
/// only available once the product exists (needs a real product_id for the
/// storage path).
///
/// After a successful create, this stays on the SAME screen/route and just
/// switches its internal state into edit mode for the new id — it does NOT
/// navigate to a separate /edit route. That matters: AdminProductListScreen
/// refreshes by awaiting the Future its own `context.push(...)` returns,
/// which only resolves once this whole screen is finally popped. Hopping
/// through an extra pushReplacement route in between breaks that timing
/// (Riverpod defers a cross-screen `invalidate()` until the target provider
/// is next "listened to", which a route buried under others may not be) —
/// found via live testing: the list kept showing stale data after creating
/// a product until a full page reload.
class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AdminProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController(text: '0');
  String? _categoryId;
  bool _isActive = true;
  final List<_OptionRow> _options = [];
  bool _prefilled = false;
  bool _optionsPrefilled = false;
  bool _saving = false;
  late String? _currentProductId = widget.productId;

  bool get _isEdit => _currentProductId != null;

  @override
  void dispose() {
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  void _prefill(Product p) {
    if (_prefilled) return;
    _prefilled = true;
    _skuCtrl.text = p.sku;
    _barcodeCtrl.text = p.barcode ?? '';
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description ?? '';
    _costCtrl.text = p.costPrice.toString();
    _priceCtrl.text = p.sellingPrice.toString();
    _minStockCtrl.text = p.minStock.toString();
    _categoryId = p.categoryId;
    _isActive = p.isActive;
  }

  void _prefillOptions(List<ProductOption> options) {
    if (_optionsPrefilled) return;
    _optionsPrefilled = true;
    _options.addAll([
      for (final o in options)
        _OptionRow(id: o.id, name: o.name, priceText: o.extraPrice.toString()),
    ]);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    final optionInputs = [
      for (final o in _options)
        if (o.name.trim().isNotEmpty)
          ProductOptionInput(
            id: o.id,
            name: o.name.trim(),
            extraPrice: double.tryParse(o.priceText.trim()) ?? 0,
          ),
    ];
    try {
      if (_isEdit) {
        await repo.updateProduct(
          _currentProductId!,
          sku: _skuCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim().isEmpty
              ? null
              : _barcodeCtrl.text.trim(),
          categoryId: _categoryId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          specs: const {},
          costPrice: double.parse(_costCtrl.text),
          sellingPrice: double.parse(_priceCtrl.text),
          minStock: int.parse(_minStockCtrl.text),
        );
        await repo.setProductActive(_currentProductId!, _isActive);
        await repo.saveProductOptions(_currentProductId!, optionInputs);
        ref.invalidate(adminProductDetailProvider(_currentProductId!));
        ref.invalidate(productOptionsProvider(_currentProductId!));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
        }
      } else {
        final id = await repo.createProduct(
          sku: _skuCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim().isEmpty
              ? null
              : _barcodeCtrl.text.trim(),
          categoryId: _categoryId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          specs: const {},
          costPrice: double.parse(_costCtrl.text),
          sellingPrice: double.parse(_priceCtrl.text),
          minStock: int.parse(_minStockCtrl.text),
        );
        await repo.saveProductOptions(id, optionInputs);
        if (mounted) {
          setState(() => _currentProductId = id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء المنتج — يمكنك الآن إضافة صور'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider());
    final productAsync = _isEdit
        ? ref.watch(adminProductDetailProvider(_currentProductId!))
        : null;

    if (_isEdit && productAsync != null) {
      final p = productAsync.value;
      if (p != null) _prefill(p);
      final options = ref.watch(productOptionsProvider(_currentProductId!));
      final list = options.value;
      if (list != null) _prefillOptions(list);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل المنتج' : 'منتج جديد')),
      // Skip the loading/error wrapper once fields are already prefilled —
      // covers both a normal edit re-fetch and the moment right after this
      // screen creates a product and flips itself into edit mode, where we
      // already have every field locally and don't want the form to flash
      // away behind a spinner.
      body: _isEdit && productAsync != null && !_prefilled
          ? productAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: 'تعذَّر تحميل المنتج'),
              data: (p) => p == null
                  ? const EmptyView(message: 'المنتج غير موجود')
                  : _buildForm(categoriesAsync),
            )
          : _buildForm(categoriesAsync),
    );
  }

  Widget _buildForm(AsyncValue<List<ProductCategory>> categoriesAsync) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isEdit) ...[
            _ProductImagesSection(productId: _currentProductId!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'اسم المنتج'),
            validator: (v) => Validators.required(v, 'اسم المنتج'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU'),
                  validator: (v) => Validators.required(v, 'SKU'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الباركود (اختياري)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (cats) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'القسم'),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون قسم')),
                ...cats.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'الوصف'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _costCtrl,
                  decoration: const InputDecoration(labelText: 'سعر التكلفة'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => Validators.positiveNumber(v, 'سعر التكلفة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'سعر البيع'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => Validators.positiveNumber(v, 'سعر البيع'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _minStockCtrl,
            decoration: const InputDecoration(labelText: 'الحد الأدنى للمخزون'),
            keyboardType: TextInputType.number,
          ),
          if (_isEdit) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('المنتج نشط'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'الخيارات الإضافية',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'كل خيار يقدر العميل يختاره فيضيف سعره لسعر المنتج — لو ماختارش '
            'أي خيار، يفضل سعر المنتج زي ما هو.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ..._options.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: row.name,
                      decoration: const InputDecoration(labelText: 'الخيار'),
                      onChanged: (v) => row.name = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: row.priceText,
                      decoration: const InputDecoration(
                        labelText: 'سعر إضافي',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) => row.priceText = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.minus_cirlce_copy),
                    onPressed: () => setState(() => _options.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _options.add(_OptionRow())),
            icon: const Icon(Iconsax.add_copy),
            label: const Text('إضافة خيار'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'حفظ التعديلات' : 'إنشاء المنتج'),
          ),
        ],
      ),
    );
  }
}

class _ProductImagesSection extends ConsumerWidget {
  final String productId;
  const _ProductImagesSection({required this.productId});

  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    try {
      await ref
          .read(productRepositoryProvider)
          .uploadProductImage(productId, bytes, ext);
      ref.invalidate(productImagesProvider(productId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _deleteImage(
    BuildContext context,
    WidgetRef ref,
    ProductImage image,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف الصورة',
      message: 'هل تريد حذف هذه الصورة؟',
      isDangerous: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(productRepositoryProvider).deleteProductImage(image);
      ref.invalidate(productImagesProvider(productId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(productImagesProvider(productId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الصور', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: imagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (images) => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final img in images)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: img.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: InkWell(
                            onTap: () => _deleteImage(context, ref, img),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Iconsax.close_circle_copy,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                InkWell(
                  onTap: () => _addImage(context, ref),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Iconsax.gallery_add_copy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
