import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/all_rows.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../maintenance/data/models/technician_option.dart';
import '../../orders/data/models/order.dart';
import '../../orders/data/models/order_item.dart';
import '../../technician_account/data/models/sale.dart';
import 'models/sale_return_item.dart';

/// Where an invoice of the month came from.
enum InvoiceSource { walkIn, technician, online }

String invoiceSourceLabelAr(InvoiceSource s) => switch (s) {
  InvoiceSource.walkIn => 'بيع مباشر',
  InvoiceSource.technician => 'صنايعي',
  InvoiceSource.online => 'أونلاين',
};

/// One line of an invoice, from either a sale or an online order.
class InvoiceLine {
  final String name;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double lineTotal;
  final int returnedQuantity;

  const InvoiceLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.lineTotal,
    this.returnedQuantity = 0,
  });
}

/// A sale (walk-in or a technician's) or an online order, with its lines.
class MonthInvoice {
  final String id;
  final InvoiceSource source;
  final int number;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;

  /// The technician who sold it, or whose bag it came from.
  final String? technicianName;
  final String paymentLabel;
  final String statusLabel;

  /// Counted in the month's total (completed sales, confirmed+ orders).
  final bool counted;
  final double subtotal;
  final double discount;
  final double total;
  final double paid;
  final String? notes;
  final List<InvoiceLine> lines;

  const MonthInvoice({
    required this.id,
    required this.source,
    required this.number,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.technicianName,
    required this.paymentLabel,
    required this.statusLabel,
    required this.counted,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paid,
    this.notes,
    required this.lines,
  });

  double get remaining => (total - paid).clamp(0, double.infinity);
}

/// How many months back the month sales screen can go: this month, the
/// one before and the one before that.
const monthSalesMonthsBack = 2;

/// The calendar month [monthsAgo] months before [now]'s: its 1st, and the
/// 1st of the month after (exclusive). Local time, like the shop's day.
({DateTime from, DateTime to}) monthRange(DateTime now, int monthsAgo) => (
  from: DateTime(now.year, now.month - monthsAgo),
  to: DateTime(now.year, now.month - monthsAgo + 1),
);

/// Every invoice of the month [monthsAgo] months back (0 = this month),
/// newest first. Read-only.
final monthInvoicesProvider = FutureProvider.autoDispose
    .family<List<MonthInvoice>, int>(
      (ref, monthsAgo) => fetchMonthInvoices(
        ref.watch(supabaseClientProvider),
        monthRange(DateTime.now(), monthsAgo),
      ),
    );

/// Order statuses the dashboard counts as revenue (daily_sales_summary).
const _countedOrderStatuses = {
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.delivered,
  OrderStatus.completed,
};

Future<List<MonthInvoice>> fetchMonthInvoices(
  SupabaseClient client,
  ({DateTime from, DateTime to}) month,
) async {
  try {
    final from = month.from.toUtc().toIso8601String();
    final to = month.to.toUtc().toIso8601String();

    // A whole month can pass the server's 1000 rows a request: read it all,
    // a page at a time (ordered by id so pages don't overlap; the list is
    // sorted by date below).
    final (saleRows, orderRows, techRows) = await (
      allRows(
        () => client
            .from('sales')
            .select()
            .gte('created_at', from)
            .lt('created_at', to)
            .order('id'),
      ),
      allRows(
        () => client
            .from('orders')
            .select()
            .gte('created_at', from)
            .lt('created_at', to)
            .order('id'),
      ),
      client
          .from('technicians')
          .select('id, employee_code, users!technicians_id_fkey(full_name)'),
    ).wait;

    final techNames = {
      for (final t in techRows.map(TechnicianOption.fromRow)) t.id: t.fullName,
    };

    final saleLines = <String, List<InvoiceLine>>{};
    for (final ids in _chunks(saleRows.map((r) => r['id'] as String))) {
      final rows = await allRows(
        () => client
            .from('sale_items_with_returns')
            .select()
            .inFilter('sale_id', ids)
            .order('id'),
      );
      for (final r in rows) {
        final i = SaleReturnItem.fromRow(r);
        (saleLines[r['sale_id'] as String] ??= []).add(
          InvoiceLine(
            name: i.productNameSnapshot,
            quantity: i.quantity,
            unitPrice: i.unitPriceSnapshot,
            discount: i.discount,
            lineTotal: i.lineTotal,
            returnedQuantity: i.returnedQuantity,
          ),
        );
      }
    }

    final orderLines = <String, List<InvoiceLine>>{};
    for (final ids in _chunks(orderRows.map((r) => r['id'] as String))) {
      final rows = await allRows(
        () => client
            .from('order_items_display')
            .select()
            .inFilter('order_id', ids)
            .order('id'),
      );
      for (final r in rows) {
        final i = OrderItem.fromRow(r);
        (orderLines[i.orderId] ??= []).add(
          InvoiceLine(
            name: i.productNameSnapshot,
            quantity: i.quantity,
            unitPrice: i.unitPriceSnapshot,
            discount: i.discount,
            lineTotal: i.lineTotal,
          ),
        );
      }
    }

    final invoices = <MonthInvoice>[
      for (final r in saleRows)
        () {
          final s = Sale.fromRow(r);
          final techId =
              r['technician_id'] as String? ?? r['source_bag_id'] as String?;
          return MonthInvoice(
            id: s.id,
            source: r['technician_id'] == null
                ? InvoiceSource.walkIn
                : InvoiceSource.technician,
            number: s.saleNumber,
            createdAt: s.createdAt,
            customerName: s.customerName,
            customerPhone: s.customerPhone,
            technicianName: techId == null ? null : techNames[techId],
            paymentLabel: paymentMethodLabelAr(s.paymentMethod),
            statusLabel: saleStatusLabelAr(s.status),
            counted: s.status == SaleStatus.completed,
            subtotal: s.subtotal,
            discount: s.discount,
            total: s.total,
            paid: s.paidAmount,
            notes: r['notes'] as String?,
            lines: saleLines[s.id] ?? const [],
          );
        }(),
      for (final r in orderRows)
        () {
          final o = Order.fromRow(r);
          return MonthInvoice(
            id: o.id,
            source: InvoiceSource.online,
            number: o.orderNumber,
            createdAt: o.createdAt,
            customerName: o.deliveryRecipientName,
            customerPhone: o.deliveryPhone,
            paymentLabel: paymentStatusLabelAr(o.paymentStatus),
            statusLabel: orderStatusLabelAr(o.status),
            counted: _countedOrderStatuses.contains(o.status),
            subtotal: o.subtotal,
            discount: o.discount,
            total: o.total,
            paid: o.paidAmount,
            notes: o.notes,
            lines: orderLines[o.id] ?? const [],
          );
        }(),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  } catch (e) {
    throw AppException.from(e);
  }
}

/// Keeps each `in (...)` filter short enough for a URL.
Iterable<List<String>> _chunks(Iterable<String> ids, [int size = 100]) sync* {
  final all = ids.toList();
  for (var i = 0; i < all.length; i += size) {
    yield all.sublist(i, i + size > all.length ? all.length : i + size);
  }
}
