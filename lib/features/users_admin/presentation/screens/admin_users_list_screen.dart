import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/users_admin_providers.dart';
import '../widgets/phone_verification_switch.dart';

class AdminUsersListScreen extends ConsumerStatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  ConsumerState<AdminUsersListScreen> createState() =>
      _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends ConsumerState<AdminUsersListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  AppRole? _roleFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(
      adminUsersListProvider(
        search: _search.isEmpty ? null : _search,
        roleFilter: _roleFilter,
      ),
    );
    final myId = ref.watch(currentUserProfileProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون والصلاحيات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminUserNewTechnician),
        icon: const Icon(Iconsax.user_add_copy),
        label: const Text('إضافة صنايعي/مبيعات/أدمن'),
      ),
      body: Column(
        children: [
          const Card(
            margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PhoneVerificationSwitch(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو رقم الهاتف',
                prefixIcon: Icon(Iconsax.search_normal_1_copy),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _RoleChip(
                  label: 'الكل',
                  selected: _roleFilter == null,
                  onTap: () => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'أدمن',
                  selected: _roleFilter == AppRole.admin,
                  onTap: () => setState(() => _roleFilter = AppRole.admin),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'صنايعي',
                  selected: _roleFilter == AppRole.technician,
                  onTap: () => setState(() => _roleFilter = AppRole.technician),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'عميل',
                  selected: _roleFilter == AppRole.customer,
                  onTap: () => setState(() => _roleFilter = AppRole.customer),
                ),
                const SizedBox(width: 8),
                _RoleChip(
                  label: 'مبيعات',
                  selected: _roleFilter == AppRole.sales,
                  onTap: () => setState(() => _roleFilter = AppRole.sales),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل المستخدمين',
                onRetry: () => ref.invalidate(adminUsersListProvider),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyView(
                    message: 'لا يوجد مستخدمون',
                    icon: Iconsax.people_copy,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return ListTile(
                      leading: CircleAvatar(child: Icon(_roleIcon(u.role))),
                      title: Text(u.fullName),
                      subtitle: Text(
                        '${_roleLabel(u.role)} · ${u.phone ?? '—'}',
                      ),
                      trailing: !u.isActive
                          ? const Chip(
                              label: Text('موقوف'),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                      onTap: () =>
                          _openUserSheet(context, u, isSelf: u.id == myId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openUserSheet(BuildContext context, AppUser u, {required bool isSelf}) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                u.fullName,
                style: Theme.of(sheetContext).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              Text(u.phone ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (!isSelf) ...[
                ListTile(
                  leading: const Icon(Iconsax.arrow_swap_horizontal_copy),
                  title: const Text('تغيير الصلاحية'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _changeRole(u);
                  },
                ),
                ListTile(
                  leading: Icon(
                    u.isActive
                        ? Iconsax.lock_slash_copy
                        : Iconsax.tick_circle_copy,
                  ),
                  title: Text(u.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _toggleActive(u);
                  },
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'لا يمكنك تعديل صلاحياتك أو إيقاف حسابك الخاص',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeRole(AppUser u) async {
    final newRole = await showDialog<AppRole>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر الصلاحية الجديدة'),
        children: AppRole.values
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r),
                child: Text(_roleLabel(r)),
              ),
            )
            .toList(),
      ),
    );
    if (newRole == null || newRole == u.role || !mounted) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'تأكيد تغيير الصلاحية',
      message:
          'سيتم تحويل ${u.fullName} إلى "${_roleLabel(newRole)}". هل أنت متأكد؟',
      isDangerous: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(usersAdminRepositoryProvider).setRole(u.id, newRole);
      ref.invalidate(adminUsersListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _toggleActive(AppUser u) async {
    final confirmed = await showConfirmDialog(
      context,
      title: u.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب',
      message: u.isActive
          ? 'لن يستطيع ${u.fullName} الدخول للتطبيق بعد الإيقاف.'
          : 'سيستطيع ${u.fullName} الدخول للتطبيق من جديد.',
      isDangerous: u.isActive,
    );
    if (!confirmed) return;

    try {
      await ref.read(usersAdminRepositoryProvider).setActive(u.id, !u.isActive);
      ref.invalidate(adminUsersListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  IconData _roleIcon(AppRole r) => switch (r) {
    AppRole.admin => Iconsax.shield_tick_copy,
    AppRole.technician => Iconsax.setting_2_copy,
    AppRole.customer => Iconsax.user_copy,
    AppRole.sales => Iconsax.card_pos_copy,
  };

  String _roleLabel(AppRole r) => switch (r) {
    AppRole.admin => 'أدمن',
    AppRole.technician => 'صنايعي',
    AppRole.customer => 'عميل',
    AppRole.sales => 'مبيعات',
  };
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
