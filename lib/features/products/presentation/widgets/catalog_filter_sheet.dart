import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/catalog_query.dart';

/// «فلترة» bottom sheet: price range and in-stock only. Pops the updated
/// query, or null when dismissed.
Future<CatalogQuery?> showCatalogFilterSheet(
  BuildContext context,
  CatalogQuery query,
) {
  return showModalBottomSheet<CatalogQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CatalogFilterSheet(query: query),
  );
}

class CatalogFilterSheet extends StatefulWidget {
  final CatalogQuery query;
  const CatalogFilterSheet({super.key, required this.query});

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  late final _min = TextEditingController(text: _fmt(widget.query.minPrice));
  late final _max = TextEditingController(text: _fmt(widget.query.maxPrice));
  late bool _availableOnly = widget.query.availableOnly;
  String? _error;

  static String _fmt(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : '$v');

  static double? _parse(String s) =>
      s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    final min = _parse(_min.text);
    final max = _parse(_max.text);
    final error = priceRangeError(min, max);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(
      widget.query.copyWith(
        minPrice: min,
        maxPrice: max,
        availableOnly: _availableOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      LengthLimitingTextInputFormatter(9),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('فلترة المنتجات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('السعر (ج.م)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('filter-min-price'),
                  controller: _min,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: priceFormatter,
                  decoration: const InputDecoration(labelText: 'من'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('filter-max-price'),
                  controller: _max,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: priceFormatter,
                  decoration: const InputDecoration(labelText: 'إلى'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('المتاح فقط'),
            subtitle: const Text('إخفاء المنتجات غير المتوفرة حاليًا'),
            value: _availableOnly,
            onChanged: (v) => setState(() => _availableOnly = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(
                    widget.query.copyWith(
                      minPrice: null,
                      maxPrice: null,
                      availableOnly: false,
                    ),
                  ),
                  child: const Text('مسح'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('عرض النتائج'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
