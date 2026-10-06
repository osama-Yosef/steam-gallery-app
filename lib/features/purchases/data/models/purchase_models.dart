/// A supplier with what the gallery owes them (supplier_balances, 0075).
class SupplierBalance {
  final String id;
  final String name;
  final String? phone;
  final double totalInvoices;
  final double totalPaid;
  final double balance;
  final int invoicesCount;

  const SupplierBalance({
    required this.id,
    required this.name,
    this.phone,
    required this.totalInvoices,
    required this.totalPaid,
    required this.balance,
    required this.invoicesCount,
  });

  factory SupplierBalance.fromRow(Map<String, dynamic> r) => SupplierBalance(
    id: r['supplier_id'] as String,
    name: r['name'] as String,
    phone: r['phone'] as String?,
    totalInvoices: (r['total_invoices'] as num).toDouble(),
    totalPaid: (r['total_paid'] as num).toDouble(),
    balance: (r['balance'] as num).toDouble(),
    invoicesCount: (r['invoices_count'] as num).toInt(),
  );
}

/// How much of a purchase invoice has been paid.
enum PurchasePaymentState { paid, partial, deferred }

String purchasePaymentStateLabelAr(PurchasePaymentState s) => switch (s) {
  PurchasePaymentState.paid => 'مدفوعة',
  PurchasePaymentState.partial => 'مدفوعة جزئيًا',
  PurchasePaymentState.deferred => 'آجل',
};

/// A purchase invoice header (purchase_invoices_summary, 0075).
class PurchaseInvoice {
  final String id;
  final int invoiceNumber;
  final String supplierId;
  final String supplierName;
  final String? supplierPhone;
  final String? supplierInvoiceRef;
  final DateTime invoiceDate;
  final double subtotal;
  final double discount;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final int itemsCount;
  final String? notes;
  final DateTime createdAt;

  const PurchaseInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    this.supplierPhone,
    this.supplierInvoiceRef,
    required this.invoiceDate,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.itemsCount,
    this.notes,
    required this.createdAt,
  });

  PurchasePaymentState get paymentState => remainingAmount <= 0
      ? PurchasePaymentState.paid
      : paidAmount > 0
      ? PurchasePaymentState.partial
      : PurchasePaymentState.deferred;

  factory PurchaseInvoice.fromRow(Map<String, dynamic> r) => PurchaseInvoice(
    id: r['id'] as String,
    invoiceNumber: (r['invoice_number'] as num).toInt(),
    supplierId: r['supplier_id'] as String,
    supplierName: r['supplier_name'] as String,
    supplierPhone: r['supplier_phone'] as String?,
    supplierInvoiceRef: r['supplier_invoice_ref'] as String?,
    invoiceDate: DateTime.parse(r['invoice_date'] as String),
    subtotal: (r['subtotal'] as num).toDouble(),
    discount: (r['discount'] as num).toDouble(),
    total: (r['total'] as num).toDouble(),
    paidAmount: (r['paid_amount'] as num).toDouble(),
    remainingAmount: (r['remaining_amount'] as num).toDouble(),
    itemsCount: (r['items_count'] as num).toInt(),
    notes: r['notes'] as String?,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}

class PurchaseInvoiceItem {
  final String productName;
  final int quantity;
  final double unitCost;
  final double lineTotal;

  const PurchaseInvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
  });

  factory PurchaseInvoiceItem.fromRow(Map<String, dynamic> r) =>
      PurchaseInvoiceItem(
        productName: r['product_name_snapshot'] as String,
        quantity: (r['quantity'] as num).toInt(),
        unitCost: (r['unit_cost'] as num).toDouble(),
        lineTotal: (r['line_total'] as num).toDouble(),
      );
}

class SupplierPayment {
  final int paymentNumber;
  final double amount;
  final String kind;
  final String? notes;
  final DateTime createdAt;

  const SupplierPayment({
    required this.paymentNumber,
    required this.amount,
    required this.kind,
    this.notes,
    required this.createdAt,
  });

  factory SupplierPayment.fromRow(Map<String, dynamic> r) => SupplierPayment(
    paymentNumber: (r['payment_number'] as num).toInt(),
    amount: (r['amount'] as num).toDouble(),
    kind: r['kind'] as String,
    notes: r['notes'] as String?,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}

/// One line of a purchase invoice being entered.
class PurchaseLineInput {
  final String productId;
  final String productName;
  final int quantity;
  final double unitCost;

  const PurchaseLineInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  double get lineTotal => quantity * unitCost;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'unit_cost': unitCost,
  };
}
