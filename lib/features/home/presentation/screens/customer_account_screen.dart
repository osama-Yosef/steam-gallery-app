import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../locations/data/models/location_models.dart';
import '../../../locations/presentation/providers/locations_providers.dart';
import '../../../support/presentation/providers/support_providers.dart';
import '../../../../core/utils/whatsapp_launcher.dart';

/// Customer's "حسابي" tab — home for the logout action now that the old
/// catalog-screen AppBar icons moved into CustomerShell's bottom nav, plus
/// self-service profile editing (name / photo), city and addresses.
class CustomerAccountScreen extends ConsumerWidget {
  const CustomerAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      // A list, not a Column: the account page keeps growing (addresses,
      // city, verification) and must scroll on small phones.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: ClipOval(
                    child: profile?.avatarUrl == null
                        ? const Icon(
                            Iconsax.user_copy,
                            color: Colors.white,
                            size: 28,
                          )
                        : CachedNetworkImage(
                            imageUrl: profile!.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorWidget: (_, _, _) => const Icon(
                              Iconsax.user_copy,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (profile?.phone != null)
                        Text(
                          profile!.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (profile != null)
                  IconButton(
                    icon: const Icon(Iconsax.edit_copy),
                    tooltip: 'تعديل الحساب',
                    onPressed: () => _showEditSheet(context, ref, profile),
                  ),
              ],
            ),
          ),
          if (profile != null && !profile.isPhoneVerified) ...[
            const SizedBox(height: 16),
            GlassPanel(
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(
                  Iconsax.shield_tick_copy,
                  color: AppColors.warning,
                ),
                title: const Text('أكِّد رقم هاتفك'),
                subtitle: const Text('خطوة سريعة بكود في رسالة لحماية حسابك'),
                trailing: const Icon(Iconsax.arrow_left_2_copy),
                onTap: () => context.push(Routes.verifyPhone),
              ),
            ),
          ],
          const SizedBox(height: 16),
          GlassPanel(
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(
                Iconsax.wallet_copy,
                color: AppColors.primaryDark,
              ),
              title: const Text('المحفظة'),
              trailing: const Icon(Iconsax.arrow_left_2_copy),
              onTap: () => context.push(Routes.customerWallet),
            ),
          ),
          const SizedBox(height: 16),
          const _SupportSection(),
          const SizedBox(height: 16),
          const _LocationSection(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'تسجيل الخروج',
                message: 'هل تريد تسجيل الخروج من حسابك؟',
              );
              if (confirmed) await ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Iconsax.logout_copy, color: AppColors.danger),
            label: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppColors.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, AppUser profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _nameCtrl = TextEditingController(text: widget.profile.fullName);
  Uint8List? _avatarBytes;
  String? _avatarExt;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateMyProfile(
            fullName: _nameCtrl.text.trim(),
            avatarBytes: _avatarBytes,
            avatarExt: _avatarExt,
          );
      ref.invalidate(currentUserProfileProvider);
      if (mounted) Navigator.of(context).pop();
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تعديل الحساب', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _avatarBytes != null
                    ? MemoryImage(_avatarBytes!)
                    : (widget.profile.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              widget.profile.avatarUrl!,
                            )
                          : null),
                child: _avatarBytes == null && widget.profile.avatarUrl == null
                    ? const Icon(Iconsax.user_copy, size: 36)
                    : null,
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _pickAvatar,
              child: const Text('تغيير الصورة'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'الاسم الكامل'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

/// "تواصل معنا" — opens a WhatsApp chat with the business's support number
/// (0056, admin-editable). Hidden entirely while unconfigured rather than
/// showing a dead button.
class _SupportSection extends ConsumerWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whatsapp = ref.watch(supportWhatsappProvider).value;
    if (whatsapp == null || whatsapp.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Iconsax.message_question_copy, color: Color(0xFF25D366)),
        title: const Text('تواصل معنا'),
        subtitle: const Text('في مشكلة أو استفسار؟ راسلنا على واتساب'),
        trailing: const Icon(Iconsax.arrow_left_2_copy),
        onTap: () => WhatsappLauncher.open(whatsapp),
      ),
    );
  }
}

/// Country, city and saved addresses. Country is shown, not chosen: the
/// launch is Egypt-only, and the city list already comes from active
/// countries only.
class _LocationSection extends ConsumerWidget {
  const _LocationSection();

  Future<void> _pickCity(
    BuildContext context,
    WidgetRef ref,
    List<City> cities,
    String? current,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اختر مدينتك', textAlign: TextAlign.center),
            ),
            for (final c in cities)
              ListTile(
                title: Text(c.nameAr),
                trailing: c.id == current ? const Icon(Iconsax.tick_circle_copy) : null,
                onTap: () => Navigator.of(ctx).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !context.mounted) return;
    try {
      await ref.read(locationsRepositoryProvider).setMyCity(picked);
      ref.invalidate(myCityIdProvider);
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
    final cities = ref.watch(citiesProvider()).value ?? const <City>[];
    final countries = ref.watch(countriesProvider).value ?? const <Country>[];
    final myCityId = ref.watch(myCityIdProvider).value;
    final addresses = ref.watch(myAddressesProvider).value;
    final city = cities.where((c) => c.id == myCityId).firstOrNull;
    final country = city == null
        ? countries.firstOrNull
        : countries.where((c) => c.id == city.countryId).firstOrNull;

    final addressCount = addresses?.length;
    final defaultAddress = addresses?.where((a) => a.isDefault).firstOrNull;

    return GlassPanel(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Iconsax.flag_copy),
            title: const Text('الدولة'),
            trailing: Text(country?.nameAr ?? '—'),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('account-city'),
            leading: const Icon(Iconsax.buildings_copy),
            title: const Text('المدينة'),
            subtitle: Text(city?.nameAr ?? 'لم تُحدَّد'),
            trailing: const Icon(Iconsax.arrow_left_2_copy),
            onTap: cities.isEmpty
                ? null
                : () => _pickCity(context, ref, cities, myCityId),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('account-addresses'),
            leading: const Icon(Iconsax.building_copy),
            title: Text(
              addressCount == null || addressCount == 0
                  ? 'عناويني'
                  : 'عناويني ($addressCount)',
            ),
            subtitle: Text(
              defaultAddress == null
                  ? 'أضف عنوانك لنعرف لو الخدمة متاحة عندك'
                  : '${defaultAddress.label} — ${defaultAddress.addressLine}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Iconsax.arrow_left_2_copy),
            onTap: () => context.push(Routes.customerAddresses),
          ),
        ],
      ),
    );
  }
}
