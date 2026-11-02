import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/offline/network_status.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../data/backup_repository.dart';

/// "نسخ احتياطي": take a full backup now and save it as a file, or put a
/// backup file back. Admin only (the server checks too).
class AdminBackupScreen extends ConsumerStatefulWidget {
  const AdminBackupScreen({super.key});

  @override
  ConsumerState<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends ConsumerState<AdminBackupScreen> {
  String? _busy;

  BackupRepository get _repo =>
      BackupRepository(ref.read(supabaseClientProvider));

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _online() {
    if (NetworkStatus.instance.isOnline) return true;
    _say('النسخ الاحتياطي والاسترجاع محتاجين نت');
    return false;
  }

  /// Downloads a backup and asks where to save it. False if the person
  /// cancelled the save dialog.
  Future<bool> _saveBackup({required String title}) async {
    final now = DateTime.now();
    final bytes = await _repo.export();
    final saved = await FilePicker.saveFile(
      dialogTitle: title,
      fileName: BackupRepository.fileName(now),
      bytes: bytes,
      mimeType: 'application/json',
    );
    return saved != null;
  }

  Future<void> _backupNow() async {
    if (_busy != null || !_online()) return;
    setState(() => _busy = 'جاري تجهيز النسخة...');
    try {
      final saved = await _saveBackup(title: 'احفظ النسخة الاحتياطية');
      _say(saved ? 'تم حفظ النسخة الاحتياطية' : 'اتلغى الحفظ');
    } catch (e) {
      _say(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _restore() async {
    if (_busy != null || !_online()) return;
    final outbox = ref.read(outboxProvider);
    if (outbox.entries.isNotEmpty) {
      _say(
        'فيه عمليات على الجهاز لسه متبعتتش — استنى المزامنة الأول من شاشة "المزامنة"',
      );
      return;
    }

    final file = await FilePicker.pickFile(
      dialogTitle: 'اختار ملف النسخة الاحتياطية',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null || !mounted) return;

    final Map<String, dynamic> backup;
    final BackupInfo info;
    try {
      (info, backup) = BackupInfo.parse(await file.readAsBytes());
    } catch (e) {
      _say(AppException.from(e).messageAr);
      return;
    }
    if (!mounted) return;

    final first = await showConfirmDialog(
      context,
      title: 'استرجاع نسخة ${Formatters.dateTime(info.createdAt)}',
      message:
          'النسخة دي فيها:\n'
          '• ${info.of('sales')} فاتورة بيع\n'
          '• ${info.of('expenses')} مصروف\n'
          '• ${info.of('purchase_invoices')} فاتورة شراء\n'
          '• ${info.of('products')} منتج\n\n'
          'كل البيانات الحالية على كل الأجهزة هتتشال وترجع زي ما كانت وقت النسخة دي. '
          'أي حاجة اتسجلت بعدها هتروح.',
      confirmLabel: 'كمّل',
      isDangerous: true,
    );
    if (!first || !mounted) return;

    final second = await showConfirmDialog(
      context,
      title: 'متأكد؟',
      message:
          'هناخد نسخة من البيانات الحالية الأول وتحفظها، وبعدين نرجّع النسخة اللي اخترتها.',
      confirmLabel: 'استرجع',
      isDangerous: true,
    );
    if (!second || !mounted) return;

    setState(() => _busy = 'بناخد نسخة من البيانات الحالية...');
    try {
      // Undo first: the current data, saved where the person chooses.
      final saved = await _saveBackup(
        title: 'احفظ نسخة من البيانات الحالية قبل الاسترجاع',
      );
      if (!saved) {
        _say('اتلغى الاسترجاع — لازم تحفظ نسخة من الحالي الأول');
        return;
      }
      if (mounted) setState(() => _busy = 'جاري الاسترجاع...');
      await _repo.restore(backup);
      outbox.markServerChanged();
      _say('تم الاسترجاع — البيانات رجعت زي ما كانت وقت النسخة');
    } catch (e) {
      _say('${AppException.from(e).messageAr} — البيانات متغيرتش');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busy;
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Iconsax.document_download_copy),
                      SizedBox(width: 8),
                      Text(
                        'نسخ احتياطي الآن',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نسخة كاملة من كل البيانات دلوقتي: الفواتير، المصاريف، الخزن، '
                    'المخزون، الموظفين، العملاء والموردين. بتتحفظ في ملف تختار مكانه — '
                    'خلّي نسخة منه برا الجهاز (فلاشة أو Drive).',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy == null ? _backupNow : null,
                    icon: const Icon(Iconsax.document_download_copy),
                    label: const Text('نسخ احتياطي الآن'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Iconsax.document_upload_copy,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'استرجاع نسخة احتياطية',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'بيرجّع كل البيانات زي ما كانت في ملف النسخة اللي تختاره، على كل الأجهزة. '
                    'قبلها بنحفظ نسخة من الحالي عشان لو اخترت ملف غلط ترجع تاني. '
                    'لو حصل أي خطأ في النص، مفيش حاجة بتتغير.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: busy == null ? _restore : null,
                    icon: const Icon(Iconsax.document_upload_copy),
                    label: const Text('استرجاع نسخة احتياطية'),
                  ),
                ],
              ),
            ),
          ),
          if (busy != null) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Text(busy, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
