import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../data/models/storefront_models.dart';
import '../../providers/storefront_providers.dart';
import '../../widgets/marketing_form_parts.dart';

/// Add ([offerId] null) or edit a special offer and choose its products.
/// Offers are promotional only: prices shown stay the products' own prices.
class AdminOfferEditorScreen extends ConsumerStatefulWidget {
  final String? offerId;
  const AdminOfferEditorScreen({super.key, this.offerId});

  @override
  ConsumerState<AdminOfferEditorScreen> createState() =>
      _AdminOfferEditorScreenState();
}

class _AdminOfferEditorScreenState
    extends ConsumerState<AdminOfferEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  String? _imageUrl;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isActive = false;
  // Key present = product selected for this offer; value = its discounted
  // price text (empty = featured only, at the normal price).
  final Map<String, TextEditingController> _selectedProducts = {};
  String _productSearch = '';
  bool _loaded = false;
  bool _saving = false;

  bool get _isEdit => widget.offerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final repo = ref.read(storefrontRepositoryProvider);
    try {
      final offers = await ref.read(adminOffersProvider.future);
      final offer = offers.where((o) => o.id == widget.offerId).firstOrNull;
      final products = await repo.getOfferProductInputs(widget.offerId!);
      if (!mounted) return;
      setState(() {
        if (offer != null) {
          _titleCtrl.text = offer.title;
          _subtitleCtrl.text = offer.subtitle ?? '';
          _badgeCtrl.text = offer.badgeText ?? '';
          _descriptionCtrl.text = offer.description ?? '';
          _imageUrl = offer.imageUrl;
          _startsAt = offer.startsAt;
          _endsAt = offer.endsAt;
          _isActive = offer.isActive;
        }
        for (final p in products) {
          _selectedProducts[p.productId] = TextEditingController(
            text: p.offerPrice?.toStringAsFixed(2) ?? '',
          );
        }
        _loaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _subtitleCtrl,
      _badgeCtrl,
      _descriptionCtrl,
      _productSearchCtrl,
      ..._selectedProducts.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final scheduleProblem = scheduleError(_startsAt, _endsAt);
    final messenger = ScaffoldMessenger.of(context);
    if (scheduleProblem != null) {
      messenger.showSnackBar(SnackBar(content: Text(scheduleProblem)));
      return;
    }
    for (final entry in _selectedProducts.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty && double.tryParse(text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سعر العرض المكتوب غير صحيح')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(storefrontRepositoryProvider)
          .saveOffer(
            OfferInput(
              id: widget.offerId,
              title: _titleCtrl.text,
              subtitle: _subtitleCtrl.text,
              badgeText: _badgeCtrl.text,
              description: _descriptionCtrl.text,
              imageUrl: _imageUrl,
              startsAt: _startsAt,
              endsAt: _endsAt,
              isActive: _isActive,
              products: [
                for (final entry in _selectedProducts.entries)
                  OfferProductInput(
                    productId: entry.key,
                    offerPrice: double.tryParse(entry.value.text.trim()),
                  ),
              ],
            ),
          );
      ref.invalidate(adminOffersProvider);
      messenger.showSnackBar(const SnackBar(content: Text('تم حفظ العرض')));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).messageAr)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'تعديل العرض' : 'عرض جديد';
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const LoadingView(),
      );
    }
    final productsAsync = ref.watch(adminProductsProvider());

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MarketingImageField(
              folder: 'offers',
              url: _imageUrl,
              label: 'صورة العرض (اختياري)',
              onUploaded: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'عنوان العرض',
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب عنوان العرض' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _badgeCtrl,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'شارة قصيرة (مثال: توصيل مجاني)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleCtrl,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'سطر فرعي (اختياري)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'تفاصيل العرض (اختياري)',
              ),
            ),
            const SizedBox(height: 12),
            ScheduleFields(
              startsAt: _startsAt,
              endsAt: _endsAt,
              onStartsChanged: (d) => setState(() => _startsAt = d),
              onEndsChanged: (d) => setState(() => _endsAt = d),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مفعّل'),
              subtitle: const Text('يظهر للعملاء خلال فترة العرض فقط'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const Divider(),
            Text(
              'منتجات العرض (${_selectedProducts.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Text(
              'اختياري: اكتب سعر مخفَّض لمنتج فيسري طول ما العرض شغال، ويرجع '
              'السعر العادي تلقائيًا لما العرض يتوقف أو ينتهي.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productSearchCtrl,
              decoration: const InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: Icon(Iconsax.search_normal_1_copy),
              ),
              onChanged: (v) => setState(() => _productSearch = v.trim()),
            ),
            productsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingView(),
              ),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المنتجات',
                onRetry: () => ref.invalidate(adminProductsProvider),
              ),
              data: (products) {
                final candidates = products
                    .where((p) => p.isActive && !p.isService)
                    .where(
                      (p) =>
                          _productSearch.isEmpty ||
                          p.name.contains(_productSearch),
                    )
                    .toList();
                return Column(
                  children: [
                    for (final p in candidates)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _selectedProducts.containsKey(p.id),
                            title: Text(p.name),
                            subtitle: Text(Formatters.currency(p.sellingPrice)),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selectedProducts[p.id] =
                                    TextEditingController();
                              } else {
                                _selectedProducts.remove(p.id)?.dispose();
                              }
                            }),
                          ),
                          if (_selectedProducts.containsKey(p.id))
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 32,
                                bottom: 12,
                              ),
                              child: TextField(
                                controller: _selectedProducts[p.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'سعر العرض (اختياري)',
                                  hintText:
                                      'اتركه فاضي للعرض بدون تخفيض السعر',
                                  helperText:
                                      'السعر العادي: '
                                      '${Formatters.currency(p.sellingPrice)}',
                                  isDense: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ العرض'),
            ),
          ],
        ),
      ),
    );
  }
}
