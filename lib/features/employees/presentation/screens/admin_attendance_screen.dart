import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/employee_models.dart';
import '../providers/employees_providers.dart';

Color attendanceStatusColor(AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => AppColors.success,
  AttendanceStatus.absent => AppColors.danger,
  AttendanceStatus.late => AppColors.warning,
  AttendanceStatus.leave => AppColors.info,
};

/// One day's attendance for every working employee: tap a status per
/// person, or mark everyone present and change the exceptions. Saving
/// replaces that day's marks; an earlier day can be corrected the same way.
class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  /// Edits not saved yet: a status, or null for "no mark".
  final Map<String, AttendanceStatus?> _edits = {};
  bool _saving = false;

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || DateUtils.isSameDay(picked, _day)) return;
    if (_edits.isNotEmpty && !await _confirmDiscard()) return;
    setState(() {
      _day = DateUtils.dateOnly(picked);
      _edits.clear();
    });
  }

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text('في تعديلات لم تُحفظ. تجاهلها؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تجاهل'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _save(Map<String, AttendanceRecord> saved) async {
    final marks = <String, AttendanceStatus>{};
    final cleared = <String>{};
    _edits.forEach((id, status) {
      if (status != null) {
        if (saved[id]?.status != status) marks[id] = status;
      } else if (saved.containsKey(id)) {
        cleared.add(id);
      }
    });
    if (marks.isEmpty && cleared.isEmpty) {
      setState(_edits.clear);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(employeesRepositoryProvider)
          .saveAttendance(_day, marks, cleared: cleared);
      ref.invalidate(attendanceForDayProvider(_day));
      if (mounted) {
        setState(_edits.clear);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الحضور')));
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
    final employeesAsync = ref.watch(employeesProvider);
    final savedAsync = ref.watch(attendanceForDayProvider(_day));

    return PopScope(
      canPop: _edits.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          setState(_edits.clear);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('الحضور والغياب')),
        body: switch ((employeesAsync, savedAsync)) {
          (AsyncError(), _) || (_, AsyncError()) => ErrorView(
            message: 'تعذَّر تحميل الحضور',
            onRetry: () {
              ref.invalidate(employeesProvider);
              ref.invalidate(attendanceForDayProvider(_day));
            },
          ),
          (AsyncData(value: final all), AsyncData(value: final saved)) => _body(
            all.where((e) => e.isActive).toList(),
            saved,
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }

  Widget _body(List<Employee> staff, Map<String, AttendanceRecord> saved) {
    AttendanceStatus? statusOf(String id) =>
        _edits.containsKey(id) ? _edits[id] : saved[id]?.status;
    final counts = {
      for (final s in AttendanceStatus.values)
        s: staff.where((e) => statusOf(e.id) == s).length,
    };
    final unmarked = staff.where((e) => statusOf(e.id) == null).length;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: ListTile(
            leading: const Icon(Iconsax.calendar_1_copy),
            title: Text(Formatters.date(_day)),
            subtitle: Text(
              DateUtils.isSameDay(_day, DateTime.now())
                  ? 'النهارده — اضغط لاختيار يوم تاني'
                  : 'اضغط لاختيار يوم تاني',
            ),
            onTap: _pickDay,
          ),
        ),
        if (staff.isEmpty)
          const Expanded(
            child: EmptyView(
              message: 'لا يوجد موظفين يعملون حاليًا',
              icon: Iconsax.people_copy,
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    children: [
                      for (final s in AttendanceStatus.values)
                        Text(
                          '${attendanceStatusLabelAr(s)}: ${counts[s]}',
                          style: TextStyle(color: attendanceStatusColor(s)),
                        ),
                      if (unmarked > 0) Text('بدون تسجيل: $unmarked'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    for (final e in staff) {
                      if (statusOf(e.id) == null) {
                        _edits[e.id] = AttendanceStatus.present;
                      }
                    }
                  }),
                  child: const Text('الباقي حاضر'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: staff.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = staff[i];
                final current = statusOf(e.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.fullName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in AttendanceStatus.values)
                            ChoiceChip(
                              label: Text(attendanceStatusLabelAr(s)),
                              selected: current == s,
                              selectedColor: attendanceStatusColor(
                                s,
                              ).withValues(alpha: 0.25),
                              onSelected: (on) =>
                                  setState(() => _edits[e.id] = on ? s : null),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || _edits.isEmpty
                      ? null
                      : () => _save(saved),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.tick_circle_copy),
                  label: const Text('حفظ الحضور'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
