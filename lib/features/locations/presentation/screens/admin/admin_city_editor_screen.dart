import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/maps/geo_point.dart';
import '../../../../../core/maps/map_widget_factory.dart';
import '../../../../../core/maps/maps_providers.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/location_models.dart';
import '../../providers/locations_providers.dart';

/// Adds a city: its name and where the map should open for it. New cities
/// start switched off — add its areas first, then switch it on.
class AdminCityEditorScreen extends ConsumerStatefulWidget {
  const AdminCityEditorScreen({super.key});

  @override
  ConsumerState<AdminCityEditorScreen> createState() =>
      _AdminCityEditorScreenState();
}

class _AdminCityEditorScreenState extends ConsumerState<AdminCityEditorScreen> {
  // Cairo: a sensible first view for an Egypt-first launch.
  static const _fallbackCenter = GeoPoint(30.0444196, 31.2357116);

  final _formKey = GlobalKey<FormState>();
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  String? _countryId;
  GeoPoint _center = _fallbackCenter;
  bool _saving = false;

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(locationsRepositoryProvider)
          .createCity(
            countryId: _countryId!,
            nameAr: _nameArCtrl.text,
            nameEn: _nameEnCtrl.text,
            center: _center,
          );
      ref.invalidate(citiesProvider(activeOnly: false));
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة المدينة (متوقفة). أضف مناطقها ثم فعّلها.'),
        ),
      );
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
    final countriesAsync = ref.watch(countriesProvider);
    final List<Country>? countries = countriesAsync.value;
    if (countries == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مدينة جديدة')),
        body: countriesAsync.hasError
            ? ErrorView(
                message: 'تعذَّر تحميل الدول',
                onRetry: () => ref.invalidate(countriesProvider),
              )
            : const LoadingView(),
      );
    }
    _countryId ??=
        (countries.where((c) => c.isActive).firstOrNull ??
                countries.firstOrNull)
            ?.id;
    final mapFactory = ref.watch(mapWidgetFactoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مدينة جديدة')),
      body: Column(
        children: [
          Expanded(
            child: mapFactory.locationPicker(
              initialCenter: _center,
              initialZoom: MapZoom.city,
              onCenterChanged: (p) => _center = p,
            ),
          ),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'حرّك الخريطة حتى يكون المؤشر على وسط المدينة.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _countryId,
                    decoration: const InputDecoration(labelText: 'الدولة'),
                    items: [
                      for (final c in countries)
                        DropdownMenuItem(value: c.id, child: Text(c.nameAr)),
                    ],
                    onChanged: (v) => setState(() => _countryId = v),
                    validator: (v) => v == null ? 'اختر الدولة' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameArCtrl,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'الاسم بالعربي',
                            counterText: '',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nameEnCtrl,
                          maxLength: 80,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'English (optional)',
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('إضافة المدينة'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
