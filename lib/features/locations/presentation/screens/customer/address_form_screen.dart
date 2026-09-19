import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/maps/device_location_service.dart';
import '../../../../../core/maps/geo_point.dart';
import '../../../../../core/maps/map_widget_factory.dart';
import '../../../../../core/maps/maps_providers.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/location_models.dart';
import '../../providers/locations_providers.dart';
import '../../widgets/availability_badge.dart';

/// Add ([addressId] null) or edit an address in two short steps:
///   1. drop the pin (with live "is this covered?" from the server);
///   2. the words — address line (suggested from the pin), a label, and
///      optional details tucked away.
class AddressFormScreen extends ConsumerStatefulWidget {
  final String? addressId;
  const AddressFormScreen({super.key, this.addressId});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

enum _Step { pin, details }

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  _Step _step = _Step.pin;
  bool _initialised = false;

  String? _cityId;
  GeoPoint? _pin;
  MapPickerController? _map;

  ServiceAvailability? _availability;
  bool _checking = false;
  int _checkSeq = 0;
  bool _locating = false;

  final _formKey = GlobalKey<FormState>();
  final _lineCtrl = TextEditingController();
  final _customLabelCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _label = _labels.first;
  bool _makeDefault = false;
  bool _wasDefault = false;
  bool _suggesting = false;
  GeoPoint? _suggestedFor;
  bool _saving = false;

  static const _labels = ['المنزل', 'العمل'];
  static const _otherLabel = 'أخرى';

  bool get _isEdit => widget.addressId != null;

  @override
  void dispose() {
    for (final c in [
      _lineCtrl,
      _customLabelCtrl,
      _buildingCtrl,
      _floorCtrl,
      _apartmentCtrl,
      _landmarkCtrl,
      _recipientCtrl,
      _phoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Seeds the form once: from the address being edited, else the customer's
  /// city (or the first active one) centred on the map.
  void _initialise(
    List<City> cities,
    String? myCityId,
    CustomerAddress? existing,
  ) {
    if (_initialised) return;
    _initialised = true;
    if (existing != null) {
      _cityId = existing.cityId;
      _pin = existing.location;
      _lineCtrl.text = existing.addressLine;
      if (_labels.contains(existing.label)) {
        _label = existing.label;
      } else {
        _label = _otherLabel;
        _customLabelCtrl.text = existing.label;
      }
      _buildingCtrl.text = existing.building ?? '';
      _floorCtrl.text = existing.floor ?? '';
      _apartmentCtrl.text = existing.apartment ?? '';
      _landmarkCtrl.text = existing.landmark ?? '';
      _recipientCtrl.text = existing.recipientName ?? '';
      _phoneCtrl.text = existing.phone ?? '';
      _wasDefault = existing.isDefault;
      _makeDefault = existing.isDefault;
      _suggestedFor = existing.location;
    } else {
      final city = cities.firstWhere(
        (c) => c.id == myCityId,
        orElse: () => cities.first,
      );
      _cityId = city.id;
      _pin = city.center;
    }
  }

  Future<void> _checkAvailability(GeoPoint point) async {
    final cityId = _cityId;
    if (cityId == null) return;
    final seq = ++_checkSeq;
    setState(() => _checking = true);
    try {
      final result = await ref
          .read(locationsRepositoryProvider)
          .checkAvailability(cityId, point);
      // A later pin move already started a newer check: drop this answer.
      if (!mounted || seq != _checkSeq) return;
      setState(() => _availability = result);
    } catch (_) {
      if (!mounted || seq != _checkSeq) return;
      setState(() => _availability = null);
    } finally {
      if (mounted && seq == _checkSeq) setState(() => _checking = false);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final here = await ref
          .read(deviceLocationServiceProvider)
          .currentPosition();
      _map?.moveTo(here, zoom: MapZoom.street);
    } on DeviceLocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.messageAr)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _changeCity(City city) {
    setState(() {
      _cityId = city.id;
      _availability = null;
    });
    _map?.moveTo(city.center, zoom: MapZoom.city);
  }

  void _confirmPin() {
    setState(() => _step = _Step.details);
    final pin = _pin;
    // Suggest an address line for a new pin, but never overwrite what the
    // customer typed for the pin they already described.
    if (pin != null && pin != _suggestedFor) _suggestLine(pin);
  }

  Future<void> _suggestLine(GeoPoint pin) async {
    _suggestedFor = pin;
    setState(() => _suggesting = true);
    final suggestion = await ref
        .read(geocodingServiceProvider)
        .reverseGeocode(pin);
    if (!mounted) return;
    setState(() => _suggesting = false);
    if (suggestion != null && _lineCtrl.text.trim().isEmpty) {
      _lineCtrl.text = suggestion;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final cityId = _cityId;
    final pin = _pin;
    if (cityId == null || pin == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await ref
          .read(locationsRepositoryProvider)
          .saveMyAddress(
            AddressInput(
              id: widget.addressId,
              cityId: cityId,
              label: _label == _otherLabel
                  ? _customLabelCtrl.text.trim()
                  : _label,
              addressLine: _lineCtrl.text.trim(),
              location: pin,
              building: _buildingCtrl.text,
              floor: _floorCtrl.text,
              apartment: _apartmentCtrl.text,
              landmark: _landmarkCtrl.text,
              recipientName: _recipientCtrl.text,
              phone: _phoneCtrl.text,
              makeDefault: _makeDefault && !_wasDefault,
            ),
          );
      ref.invalidate(myAddressesProvider);
      final a = result.availability;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            a.available
                ? 'تم حفظ العنوان — الخدمة متاحة${a.serviceAreaName == null ? '' : ' في ${a.serviceAreaName}'}'
                : 'تم حفظ العنوان، لكن المنطقة غير مغطاة حاليًا',
          ),
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
    final citiesAsync = ref.watch(citiesProvider());
    final myCityAsync = ref.watch(myCityIdProvider);
    final addressesAsync = _isEdit
        ? ref.watch(myAddressesProvider)
        : const AsyncValue<List<CustomerAddress>>.data([]);

    final title = _isEdit ? 'تعديل العنوان' : 'عنوان جديد';

    if (citiesAsync.hasError || addressesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ErrorView(
          message: 'تعذَّر التحميل',
          onRetry: () {
            ref.invalidate(citiesProvider());
            ref.invalidate(myAddressesProvider);
          },
        ),
      );
    }
    final cities = citiesAsync.value;
    final addresses = addressesAsync.value;
    if (cities == null || addresses == null || myCityAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const LoadingView(),
      );
    }
    if (cities.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyView(
          message: 'الخدمة لم تبدأ في أي مدينة بعد.',
          icon: Iconsax.buildings_2_copy,
        ),
      );
    }

    CustomerAddress? existing;
    if (_isEdit) {
      existing = addresses.where((a) => a.id == widget.addressId).firstOrNull;
      if (existing == null) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const EmptyView(message: 'العنوان غير موجود'),
        );
      }
    }
    _initialise(cities, myCityAsync.value, existing);

    return PopScope(
      canPop: _step == _Step.pin,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = _Step.pin);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_step == _Step.pin ? 'حدد الموقع على الخريطة' : title),
        ),
        body: _step == _Step.pin ? _pinStep(cities) : _detailsStep(cities),
      ),
    );
  }

  Widget _pinStep(List<City> cities) {
    final mapFactory = ref.watch(mapWidgetFactoryProvider);
    final cityId = _cityId!;
    final areas = ref.watch(serviceAreasProvider(cityId)).value ?? const [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: DropdownButtonFormField<String>(
            key: const Key('address-city'),
            // An old address may sit in a city that has since been switched
            // off: show no selection, and the server refuses to save it
            // there (CITY_NOT_AVAILABLE) until another city is picked.
            initialValue: cities.any((c) => c.id == cityId) ? cityId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المدينة',
              prefixIcon: Icon(Iconsax.buildings_2_copy),
            ),
            items: [
              for (final c in cities)
                DropdownMenuItem(value: c.id, child: Text(c.nameAr)),
            ],
            onChanged: (id) {
              if (id == null || id == _cityId) return;
              _changeCity(cities.firstWhere((c) => c.id == id));
            },
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: mapFactory.locationPicker(
                  initialCenter: _pin!,
                  initialZoom: _isEdit ? MapZoom.street : MapZoom.city,
                  circles: [for (final a in areas) a.toCircle()],
                  onControllerReady: (c) => _map = c,
                  onCenterChanged: (p) {
                    _pin = p;
                    if (_availability != null && !_checking) {
                      setState(() => _availability = null);
                    }
                  },
                  onCenterSettled: _checkAvailability,
                ),
              ),
              PositionedDirectional(
                end: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'my-location',
                  tooltip: 'موقعي الحالي',
                  onPressed: _locating ? null : _useMyLocation,
                  child: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.gps_copy),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 36,
                  child: Center(
                    child: _checking || _availability == null
                        ? Text(
                            _checking
                                ? 'جاري التحقق من تغطية المنطقة…'
                                : 'حرّك الخريطة حتى يكون المؤشر على مكانك',
                            key: const Key('address-coverage-hint'),
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : AvailabilityBadge(
                            key: const Key('address-coverage'),
                            available: _availability!.available,
                            areaName: _availability!.serviceAreaName,
                          ),
                  ),
                ),
                if (_availability?.available == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'تقدر تحفظ العنوان، لكن لن تستطيع الطلب عليه قبل تغطية المنطقة.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('address-confirm-pin'),
                  onPressed: _confirmPin,
                  child: const Text('تأكيد الموقع'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsStep(List<City> cities) {
    final mapFactory = ref.watch(mapWidgetFactoryProvider);
    final city = cities.where((c) => c.id == _cityId).firstOrNull;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: mapFactory.preview(center: _pin!, marker: _pin),
                  ),
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: () => setState(() => _step = _Step.pin),
                      icon: const Icon(Iconsax.edit_2_copy),
                      label: const Text('تغيير'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (city != null)
                Text(city.nameAr, style: theme.textTheme.bodySmall),
              const Spacer(),
              if (_availability != null)
                AvailabilityBadge(
                  available: _availability!.available,
                  areaName: _availability!.serviceAreaName,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('address-line'),
            controller: _lineCtrl,
            maxLength: 300,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'العنوان بالتفصيل',
              hintText: 'الشارع، المنطقة، أقرب علامة',
              counterText: '',
              prefixIcon: const Icon(Iconsax.signpost_copy),
              suffixIcon: _suggesting
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'اكتب العنوان (3 أحرف على الأقل)'
                : null,
          ),
          const SizedBox(height: 16),
          Text('اسم العنوان', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final l in [..._labels, _otherLabel])
                ChoiceChip(
                  label: Text(l),
                  selected: _label == l,
                  onSelected: (_) => setState(() => _label = l),
                ),
            ],
          ),
          if (_label == _otherLabel) ...[
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('address-custom-label'),
              controller: _customLabelCtrl,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'مثال: بيت العائلة',
                counterText: '',
              ),
              validator: (v) =>
                  (_label == _otherLabel && (v == null || v.trim().isEmpty))
                  ? 'اكتب اسمًا للعنوان'
                  : null,
            ),
          ],
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('تفاصيل إضافية (اختياري)'),
            subtitle: const Text('العمارة، الدور، الشقة، ومن يستلم'),
            children: [
              Row(
                children: [
                  Expanded(child: _optional(_buildingCtrl, 'العمارة', 50)),
                  const SizedBox(width: 8),
                  Expanded(child: _optional(_floorCtrl, 'الدور', 20)),
                  const SizedBox(width: 8),
                  Expanded(child: _optional(_apartmentCtrl, 'الشقة', 20)),
                ],
              ),
              const SizedBox(height: 12),
              _optional(_landmarkCtrl, 'علامة مميزة', 150),
              const SizedBox(height: 12),
              _optional(_recipientCtrl, 'اسم المستلم', 100),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'هاتف للتواصل على هذا العنوان',
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[\s]'), '');
                  if (digits.isEmpty) return null;
                  return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(digits)
                      ? null
                      : 'رقم هاتف غير صحيح';
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
          if (!_wasDefault)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('اجعله العنوان الافتراضي'),
              value: _makeDefault,
              onChanged: (v) => setState(() => _makeDefault = v),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('address-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ العنوان'),
          ),
        ],
      ),
    );
  }

  Widget _optional(TextEditingController c, String label, int max) =>
      TextFormField(
        controller: c,
        maxLength: max,
        decoration: InputDecoration(labelText: label, counterText: ''),
      );
}
