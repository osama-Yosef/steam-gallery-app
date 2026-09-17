import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/maps/geo_point.dart';
import '../../../../../core/maps/map_widget_factory.dart';
import '../../../../../core/maps/maps_providers.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/location_models.dart';
import '../../providers/locations_providers.dart';

/// Add ([areaId] null) or edit a service area: drag the map to place the
/// centre, set the radius, name it. The circle is drawn live; the city's other
/// areas show in grey for reference.
class AdminServiceAreaEditorScreen extends ConsumerStatefulWidget {
  final String cityId;
  final String? areaId;

  const AdminServiceAreaEditorScreen({
    super.key,
    required this.cityId,
    this.areaId,
  });

  @override
  ConsumerState<AdminServiceAreaEditorScreen> createState() =>
      _AdminServiceAreaEditorScreenState();
}

class _AdminServiceAreaEditorScreenState
    extends ConsumerState<AdminServiceAreaEditorScreen> {
  static const _minRadiusKm = 0.5;
  static const _maxRadiusKm = 20.0;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _initialised = false;
  GeoPoint? _center;
  double _radiusKm = 3;
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initialise(City city, ServiceArea? area) {
    if (_initialised) return;
    _initialised = true;
    if (area != null) {
      _center = area.center;
      _radiusKm = area.radiusKm.clamp(_minRadiusKm, _maxRadiusKm);
      _isActive = area.isActive;
      _nameCtrl.text = area.nameAr;
      _notesCtrl.text = area.notes ?? '';
    } else {
      _center = city.center;
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(locationsRepositoryProvider)
          .saveServiceArea(
            id: widget.areaId,
            cityId: widget.cityId,
            nameAr: _nameCtrl.text,
            center: _center!,
            radiusKm: _radiusKm,
            isActive: _isActive,
            notes: _notesCtrl.text,
          );
      ref.invalidate(serviceAreasProvider(widget.cityId, activeOnly: false));
      ref.invalidate(serviceAreasProvider(widget.cityId));
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم الحفظ — تغطية عناوين العملاء اتحدّثت'),
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
    final city = ref
        .watch(citiesProvider(activeOnly: false))
        .value
        ?.where((c) => c.id == widget.cityId)
        .firstOrNull;
    final areas = ref
        .watch(serviceAreasProvider(widget.cityId, activeOnly: false))
        .value;
    final title = widget.areaId == null ? 'منطقة جديدة' : 'تعديل المنطقة';

    if (city == null || areas == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const LoadingView(),
      );
    }
    final area = widget.areaId == null
        ? null
        : areas.where((a) => a.id == widget.areaId).firstOrNull;
    if (widget.areaId != null && area == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyView(message: 'المنطقة غير موجودة'),
      );
    }
    _initialise(city, area);

    final mapFactory = ref.watch(mapWidgetFactoryProvider);
    final others = [
      for (final a in areas)
        if (a.id != widget.areaId) a.toCircle(emphasized: false),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('$title — ${city.nameAr}')),
      body: Column(
        children: [
          Expanded(
            child: mapFactory.locationPicker(
              initialCenter: _center!,
              initialZoom: MapZoom.neighbourhood - 1,
              circles: [
                ...others,
                MapCircle(center: _center!, radiusKm: _radiusKm),
              ],
              onCenterChanged: (p) => setState(() => _center = p),
            ),
          ),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنطقة',
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'اكتب اسم المنطقة'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('نصف القطر: ${_radiusKm.toStringAsFixed(1)} كم'),
                      Expanded(
                        child: Slider(
                          min: _minRadiusKm,
                          max: _maxRadiusKm,
                          divisions: ((_maxRadiusKm - _minRadiusKm) * 2)
                              .round(),
                          value: _radiusKm,
                          label: '${_radiusKm.toStringAsFixed(1)} كم',
                          onChanged: (v) => setState(() => _radiusKm = v),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('مفعّلة'),
                    subtitle: const Text(
                      'الإيقاف يجعل عناوين العملاء داخلها غير مغطاة فورًا',
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات داخلية (اختياري)',
                      counterText: '',
                    ),
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
                        : const Text('حفظ المنطقة'),
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
