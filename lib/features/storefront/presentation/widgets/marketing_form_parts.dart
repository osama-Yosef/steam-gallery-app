import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/storefront_providers.dart';

/// Picks an image and uploads it to the `marketing` bucket, reporting the
/// public URL. Downscaled on the device first: storefront images are shown
/// at phone width, so shipping a 12MP photo would only cost data.
class MarketingImageField extends ConsumerStatefulWidget {
  final String folder;
  final String? url;
  final ValueChanged<String> onUploaded;
  final double aspectRatio;
  final String label;

  const MarketingImageField({
    super.key,
    required this.folder,
    required this.url,
    required this.onUploaded,
    this.aspectRatio = 2.2,
    this.label = 'الصورة',
  });

  @override
  ConsumerState<MarketingImageField> createState() =>
      _MarketingImageFieldState();
}

class _MarketingImageFieldState extends ConsumerState<MarketingImageField> {
  bool _uploading = false;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final url = await ref
          .read(storefrontRepositoryProvider)
          .uploadMarketingImage(folder: widget.folder, bytes: bytes, ext: ext);
      widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Material(
              color: AppColors.accentSoft,
              child: InkWell(
                onTap: _uploading ? null : _pick,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.url != null)
                      CachedNetworkImage(
                        imageUrl: widget.url!,
                        fit: BoxFit.cover,
                      ),
                    if (widget.url == null || _uploading)
                      Center(
                        child: _uploading
                            ? const CircularProgressIndicator()
                            : const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 36,
                                  ),
                                  Text('اختر صورة'),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.url != null)
          TextButton.icon(
            onPressed: _uploading ? null : _pick,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('تغيير الصورة'),
          ),
      ],
    );
  }
}

/// Optional start/end date pair. Ends are taken as the end of that day, so
/// "until 20/9" still shows the offer all day on the 20th.
class ScheduleFields extends StatelessWidget {
  final DateTime? startsAt;
  final DateTime? endsAt;
  final ValueChanged<DateTime?> onStartsChanged;
  final ValueChanged<DateTime?> onEndsChanged;

  const ScheduleFields({
    super.key,
    required this.startsAt,
    required this.endsAt,
    required this.onStartsChanged,
    required this.onEndsChanged,
  });

  Future<DateTime?> _pick(BuildContext context, DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget field(
      String label,
      DateTime? value,
      ValueChanged<DateTime?> onChanged,
      DateTime Function(DateTime) normalise,
    ) => Expanded(
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'مسح',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: InkWell(
          onTap: () async {
            final d = await _pick(context, value);
            if (d != null) onChanged(normalise(d));
          },
          child: Text(value == null ? 'بدون' : Formatters.date(value)),
        ),
      ),
    );

    return Row(
      children: [
        field('يبدأ', startsAt, onStartsChanged, (d) => d),
        const SizedBox(width: 12),
        field(
          'ينتهي',
          endsAt,
          onEndsChanged,
          (d) => DateTime(d.year, d.month, d.day, 23, 59, 59),
        ),
      ],
    );
  }
}

/// Validates a schedule the same way the table's CHECK does.
String? scheduleError(DateTime? starts, DateTime? ends) =>
    (starts != null && ends != null && !ends.isAfter(starts))
    ? 'تاريخ الانتهاء لازم يكون بعد تاريخ البداية'
    : null;
