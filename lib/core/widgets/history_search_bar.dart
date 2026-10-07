import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../utils/formatters.dart';
import '../utils/history_query.dart';

/// Search field + "من / إلى" day range for a history screen. Reports a new
/// [HistoryQuery] as the person types (after a short pause) or picks days.
class HistorySearchBar extends StatefulWidget {
  final HistoryQuery query;
  final ValueChanged<HistoryQuery> onChanged;
  final String hint;

  const HistorySearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.hint,
  });

  @override
  State<HistorySearchBar> createState() => _HistorySearchBarState();
}

class _HistorySearchBarState extends State<HistorySearchBar> {
  late final _ctrl = TextEditingController(text: widget.query.text);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onText(String value) {
    _debounce?.cancel();
    // One query per pause in typing, not per keystroke.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(widget.query.copyWith(text: value));
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final q = widget.query;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: q.from != null && q.to != null
          ? DateTimeRange(start: q.from!, end: q.to!)
          : null,
    );
    if (picked == null) return;
    widget.onChanged(
      q.copyWith(from: () => picked.start, to: () => picked.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final hasRange = q.from != null || q.to != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Iconsax.search_normal_1_copy),
              isDense: true,
            ),
            onChanged: _onText,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Iconsax.calendar_1_copy, size: 18),
                  label: Text(
                    hasRange
                        ? '${q.from == null ? '…' : Formatters.date(q.from!)}'
                              ' — ${q.to == null ? '…' : Formatters.date(q.to!)}'
                        : 'كل التواريخ',
                  ),
                ),
              ),
              if (hasRange)
                IconButton(
                  tooltip: 'إلغاء التاريخ',
                  icon: const Icon(Iconsax.close_circle_copy),
                  onPressed: () => widget.onChanged(
                    q.copyWith(from: () => null, to: () => null),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
