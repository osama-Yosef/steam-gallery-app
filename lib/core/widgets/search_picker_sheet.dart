import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// A bottom sheet with a search box over [items]; returns the tapped one.
/// Filtering is local — these lists (products, suppliers) are small.
Future<T?> showSearchPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  String Function(T)? subtitle,
  String Function(T)? searchText,
  bool Function(T)? enabled,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _SearchPicker<T>(
      title: title,
      items: items,
      label: label,
      subtitle: subtitle,
      searchText: searchText ?? label,
      enabled: enabled,
    ),
  );
}

class _SearchPicker<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) label;
  final String Function(T)? subtitle;
  final String Function(T) searchText;
  final bool Function(T)? enabled;

  const _SearchPicker({
    required this.title,
    required this.items,
    required this.label,
    required this.subtitle,
    required this.searchText,
    required this.enabled,
  });

  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = widget.items
        .where(
          (i) => q.isEmpty || widget.searchText(i).toLowerCase().contains(q),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'ابحث...',
                  prefixIcon: Icon(Iconsax.search_normal_1_copy),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد نتائج'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final isEnabled = widget.enabled?.call(item) ?? true;
                        return ListTile(
                          enabled: isEnabled,
                          title: Text(widget.label(item)),
                          subtitle: widget.subtitle == null
                              ? null
                              : Text(widget.subtitle!(item)),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
