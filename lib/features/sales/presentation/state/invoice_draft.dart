import '../../../../core/offline/outbox.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../technician_account/data/models/sale.dart';
import '../../data/models/invoice_line.dart';
import 'line_change.dart';

/// A walk-in invoice being edited: its lines and the rules for changing
/// them. Plain Dart, so the editing rules are tested without a screen
/// (test/invoice_draft_test.dart).
class InvoiceDraft {
  final List<InvoiceLine> _lines;

  /// What each product had on the invoice when it was opened — that much is
  /// already out of the warehouse, so it can always be kept.
  final Map<String, int> _originalQty;

  /// The discount the draft starts from (the field's initial text).
  final double initialDiscount;

  /// True when the draft continues an edit still waiting in the offline
  /// queue rather than the server's copy.
  final bool fromPending;

  InvoiceDraft._(
    this._lines,
    this._originalQty, {
    required this.initialDiscount,
    required this.fromPending,
  });

  /// Starts from the server's lines — or, if an edit of this invoice is
  /// still waiting offline ([pendingEdits], oldest first), from the latest
  /// of those, so a second edit builds on the first instead of silently
  /// undoing it.
  factory InvoiceDraft.open(
    Sale sale,
    List<InvoiceLine> serverLines, {
    List<OutboxEntry> pendingEdits = const [],
  }) {
    final original = {for (final l in serverLines) l.productId: l.quantity};
    final meta = pendingEdits.isEmpty ? null : pendingEdits.last.meta;
    if (meta != null && meta['lines'] is List) {
      return InvoiceDraft._(
        [
          for (final e in meta['lines'] as List)
            InvoiceLine.fromJson((e as Map).cast<String, dynamic>()),
        ],
        original,
        initialDiscount:
            (meta['discount'] as num?)?.toDouble() ?? sale.discount,
        fromPending: true,
      );
    }
    return InvoiceDraft._(
      [...serverLines],
      original,
      initialDiscount: sale.discount,
      fromPending: false,
    );
  }

  List<InvoiceLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;

  double get subtotal => _lines.fold<double>(0, (s, l) => s + l.lineTotal);

  double total(double discount) => subtotal - discount;

  /// The most of [productId] the invoice can hold: what it already had plus
  /// what is left in the warehouse.
  int maxFor(String productId, List<WarehouseStockItem> stock) {
    final inStock = stock
        .where((s) => s.productId == productId)
        .fold<int>(0, (s, i) => s + i.quantity);
    return (_originalQty[productId] ?? 0) + inStock;
  }

  LineChange changeQuantity(
    String productId,
    int delta,
    List<WarehouseStockItem> stock,
  ) {
    final i = _lines.indexWhere((l) => l.productId == productId);
    if (i < 0) return LineChange.removed;
    final line = _lines[i];
    final next = line.quantity + delta;
    if (next <= 0) {
      _lines.removeAt(i);
      return LineChange.removed;
    }
    if (!line.isService && next > maxFor(productId, stock)) {
      return LineChange.overStock;
    }
    _lines[i] = line.copyWith(quantity: next);
    return LineChange.updated;
  }

  /// Adds one of [line]'s product — or, when it is already on the invoice,
  /// one more of it (within stock).
  LineChange add(InvoiceLine line, List<WarehouseStockItem> stock) {
    if (_lines.any((l) => l.productId == line.productId)) {
      return changeQuantity(line.productId, 1, stock);
    }
    _lines.add(line.copyWith(quantity: 1));
    return LineChange.updated;
  }

  void remove(String productId) =>
      _lines.removeWhere((l) => l.productId == productId);

  /// Why the draft can't be saved with [discount], or null when it can.
  String? saveProblem(double discount) {
    if (_lines.isEmpty) {
      return 'الفاتورة فاضية — لو عايز تلغيها استخدم "حذف الفاتورة"';
    }
    if (discount < 0 || discount > subtotal) return 'قيمة الخصم غير صحيحة';
    return null;
  }
}

/// The till money is collected into or refunded from by default: the one
/// the invoice was paid into.
CashboxKind defaultTillFor(Sale sale) =>
    sale.paymentMethod == PaymentMethod.cash
    ? CashboxKind.cash
    : CashboxKind.transfer;
