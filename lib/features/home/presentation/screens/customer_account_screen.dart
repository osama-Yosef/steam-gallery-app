import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Customer's "حسابي" tab — home for the logout action now that the old
/// catalog-screen AppBar icons moved into CustomerShell's bottom nav, plus
/// self-service profile editing (name / photo).
class CustomerAccountScreen extends ConsumerWidget {
  const CustomerAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    ),
                    child: ClipOval(
                      child: profile?.avatarUrl == null
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
                          : CachedNetworkImage(
                              imageUrl: profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 52,
                              height: 52,
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.fullName ?? '', style: Theme.of(context).textTheme.titleMedium),
                        if (profile?.phone != null)
                          Text(profile!.phone!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (profile != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'تعديل الحساب',
                      onPressed: () => _showEditSheet(context, ref, profile),
                    ),
                ],
              ),
            ),
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
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
            ),
          ],
        ),
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
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
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
      await ref.read(authRepositoryProvider).updateMyProfile(
            fullName: _nameCtrl.text.trim(),
            avatarBytes: _avatarBytes,
            avatarExt: _avatarExt,
          );
      ref.invalidate(currentUserProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                        ? CachedNetworkImageProvider(widget.profile.avatarUrl!)
                        : null),
                child: _avatarBytes == null && widget.profile.avatarUrl == null
                    ? const Icon(Icons.person_outline, size: 36)
                    : null,
              ),
            ),
          ),
          Center(
            child: TextButton(onPressed: _pickAvatar, child: const Text('تغيير الصورة')),
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
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
