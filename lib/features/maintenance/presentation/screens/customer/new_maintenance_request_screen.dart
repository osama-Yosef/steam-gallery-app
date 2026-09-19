import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../locations/data/models/location_models.dart';
import '../../../../locations/presentation/providers/locations_providers.dart';
import '../../../../orders/presentation/widgets/checkout_address_picker.dart';
import '../../providers/maintenance_providers.dart';

/// Maintenance requests are zone-restricted (0045): the address must be a
/// saved, service-area-covered [CustomerAddress] — same picker as checkout,
/// but here coverage BLOCKS submission instead of being informational, since
/// a technician can only be dispatched inside a service area.
class NewMaintenanceRequestScreen extends ConsumerStatefulWidget {
  const NewMaintenanceRequestScreen({super.key});

  @override
  ConsumerState<NewMaintenanceRequestScreen> createState() =>
      _NewMaintenanceRequestScreenState();
}

class _NewMaintenanceRequestScreenState
    extends ConsumerState<NewMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _prefilled = false;
  bool _submitting = false;
  String? _selectedAddressId;
  bool _autoSelected = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deviceCtrl.dispose();
    _problemCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Same policy as checkout's auto-select: prefer the default address if
  /// it's covered, otherwise the first covered one, otherwise nothing.
  void _autoSelectAddress(List<CustomerAddress> addresses) {
    if (_autoSelected || addresses.isEmpty) return;
    _autoSelected = true;
    if (addresses.any((a) => a.id == _selectedAddressId)) return;
    CustomerAddress? pick;
    for (final a in addresses) {
      if (a.isDefault && a.isServiceable) {
        pick = a;
        break;
      }
    }
    if (pick == null) {
      for (final a in addresses) {
        if (a.isServiceable) {
          pick = a;
          break;
        }
      }
    }
    _selectedAddressId = pick?.id;
  }

  Future<void> _pickAddress(List<CustomerAddress> addresses) async {
    final result = await showAddressPickerSheet(
      context,
      addresses: addresses,
      selectedId: _selectedAddressId,
    );
    if (result == addAddressSentinel) {
      if (mounted) await context.push(Routes.customerAddressNew);
      ref.invalidate(myAddressesProvider);
    } else if (result != null && mounted) {
      setState(() => _selectedAddressId = result);
    }
  }

  Future<void> _submit(String customerId, CustomerAddress address) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(maintenanceRepositoryProvider)
          .createRequest(
            customerId: customerId,
            customerName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            addressId: address.id,
            deviceType: _deviceCtrl.text.trim().isEmpty
                ? null
                : _deviceCtrl.text.trim(),
            problemDescription: _problemCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) {
        context.pushReplacement(Routes.customerMaintenanceDetail(id));
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
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null && !_prefilled) {
      _prefilled = true;
      _nameCtrl.text = profile.fullName;
      _phoneCtrl.text = profile.phone ?? '';
    }
    final addressesAsync = ref.watch(myAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('طلب صيانة جديد')),
      body: Form(
        key: _formKey,
        child: addressesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(myAddressesProvider),
              child: const Text('تعذَّر تحميل العناوين — إعادة المحاولة'),
            ),
          ),
          data: (addresses) {
            _autoSelectAddress(addresses);
            CustomerAddress? selected;
            for (final a in addresses) {
              if (a.id == _selectedAddressId) {
                selected = a;
                break;
              }
            }
            final canSubmit =
                profile != null && selected != null && selected.isServiceable;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (v) => Validators.required(v, 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: (v) => Validators.required(v, 'رقم الهاتف'),
                ),
                const SizedBox(height: 12),
                Text(
                  'عنوان الصيانة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (addresses.isEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Iconsax.location_add_copy),
                      title: const Text('أضف عنوانًا أولًا'),
                      trailing: const Icon(Iconsax.arrow_left_2_copy),
                      onTap: () async {
                        await context.push(Routes.customerAddressNew);
                        ref.invalidate(myAddressesProvider);
                      },
                    ),
                  )
                else
                  CheckoutAddressCard(
                    selected: selected,
                    onTap: () => _pickAddress(addresses),
                  ),
                if (selected != null && !selected.isServiceable) ...[
                  const SizedBox(height: 8),
                  Text(
                    'العنوان ده خارج نطاق خدمة الصيانة دلوقتي — اختر عنوانًا تانيًا.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deviceCtrl,
                  decoration: const InputDecoration(labelText: 'نوع الجهاز'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _problemCtrl,
                  decoration: const InputDecoration(labelText: 'وصف المشكلة'),
                  maxLines: 3,
                  validator: (v) => Validators.required(v, 'وصف المشكلة'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية (اختياري)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting || !canSubmit
                      ? null
                      : () => _submit(profile.id, selected!),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال الطلب'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
