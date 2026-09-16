import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../data/models/storefront_models.dart';
import '../../providers/storefront_providers.dart';
import '../../widgets/marketing_form_parts.dart';

/// Add ([bannerId] null) or edit a home banner: image, where a tap goes,
/// schedule and on/off.
class AdminBannerEditorScreen extends ConsumerStatefulWidget {
  final String? bannerId;
  const AdminBannerEditorScreen({super.key, this.bannerId});

  @override
  ConsumerState<AdminBannerEditorScreen> createState() =>
      _AdminBannerEditorScreenState();
}

class _AdminBannerEditorScreenState
    extends ConsumerState<AdminBannerEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');
  String? _imageUrl;
  BannerTarget _target = BannerTarget.none;
  String? _targetId;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isActive = false;
  bool _initialised = false;
  bool _saving = false;

  bool get _isEdit => widget.bannerId != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _initialise(HomeBanner? banner) {
    if (_initialised) return;
    _initialised = true;
    if (banner == null) return;
    _titleCtrl.text = banner.title;
    _sortCtrl.text = '${banner.sortOrder}';
    _imageUrl = banner.imageUrl;
    _target = banner.targetType;
    _targetId = banner.targetId;
    _startsAt = banner.startsAt;
    _endsAt = banner.endsAt;
    _isActive = banner.isActive;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final problem = _imageUrl == null
        ? 'اختر صورة البانر'
        : bannerTargetNeedsId(_target) && _targetId == null
        ? 'اختر وجهة البانر'
        : scheduleError(_startsAt, _endsAt);
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(storefrontRepositoryProvider)
          .saveBanner(
            BannerInput(
              id: widget.bannerId,
              title: _titleCtrl.text,
              imageUrl: _imageUrl!,
              targetType: _target,
              targetId: _targetId,
              startsAt: _startsAt,
              endsAt: _endsAt,
              isActive: _isActive,
              sortOrder: int.tryParse(_sortCtrl.text.trim()) ?? 0,
            ),
          );
      ref.invalidate(adminBannersProvider);
      messenger.showSnackBar(const SnackBar(content: Text('تم حفظ البانر')));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).messageAr)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _targetPicker() {
    DropdownButtonFormField<String> dropdown(
      String label,
      List<(String id, String name)> options,
    ) => DropdownButtonFormField<String>(
      key: ValueKey(_target),
      initialValue: options.any((o) => o.$1 == _targetId) ? _targetId : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o.$1, child: Text(o.$2)),
      ],
      onChanged: (v) => setState(() => _targetId = v),
      validator: (v) => v == null ? 'اختر $label' : null,
    );

    switch (_target) {
      case BannerTarget.offer:
        final offers = ref.watch(adminOffersProvider).value;
        return offers == null
            ? const LoadingView()
            : dropdown('العرض', [for (final o in offers) (o.id, o.title)]);
      case BannerTarget.category:
        final categories = ref.watch(categoriesProvider()).value;
        return categories == null
            ? const LoadingView()
            : dropdown('القسم', [for (final c in categories) (c.id, c.name)]);
      case BannerTarget.product:
        final products = ref.watch(adminProductsProvider()).value;
        return products == null
            ? const LoadingView()
            : dropdown('المنتج', [
                for (final p in products)
                  if (p.isActive && !p.isService) (p.id, p.name),
              ]);
      case BannerTarget.none:
      case BannerTarget.maintenance:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'تعديل البانر' : 'بانر جديد';
    if (_isEdit) {
      final banners = ref.watch(adminBannersProvider).value;
      if (banners == null) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const LoadingView(),
        );
      }
      final banner = banners.where((b) => b.id == widget.bannerId).firstOrNull;
      if (banner == null) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const EmptyView(message: 'البانر غير موجود'),
        );
      }
      _initialise(banner);
    } else {
      _initialise(null);
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MarketingImageField(
              folder: 'banners',
              url: _imageUrl,
              label: 'صورة البانر (عرض ÷ ارتفاع ≈ 2.2)',
              onUploaded: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'اسم البانر (يُقرأ لقارئ الشاشة)',
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب اسمًا للبانر' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BannerTarget>(
              initialValue: _target,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'عند الضغط يفتح'),
              items: [
                for (final t in BannerTarget.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(bannerTargetLabelAr(t)),
                  ),
              ],
              onChanged: (t) => setState(() {
                _target = t ?? BannerTarget.none;
                _targetId = null;
              }),
            ),
            const SizedBox(height: 12),
            _targetPicker(),
            const SizedBox(height: 12),
            ScheduleFields(
              startsAt: _startsAt,
              endsAt: _endsAt,
              onStartsChanged: (d) => setState(() => _startsAt = d),
              onEndsChanged: (d) => setState(() => _endsAt = d),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الترتيب (الأصغر يظهر أولًا)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مفعّل'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
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
                  : const Text('حفظ البانر'),
            ),
          ],
        ),
      ),
    );
  }
}
