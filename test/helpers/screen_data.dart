import 'screen_fixtures.dart';

// The rows below mirror what the database returns for each table, view and
// read RPC — the keys the app's row mappers read, with nested relations
// already embedded (the fake server ignores `select`, so every caller of a
// table gets the same full row).

const _now = '2026-10-07T09:30:00Z';
const _today = '2026-10-07';

Map<String, dynamic> _product(String id, String name, {bool service = false}) =>
    {
      'id': id,
      'sku': 'SKU-$id',
      'barcode': null,
      'category_id': 'cat-1',
      'name': name,
      'description': 'وصف $name',
      'specs': {'الضمان': 'سنة'},
      'cost_price': 600,
      'selling_price': 1000,
      'min_stock': 2,
      'is_active': true,
      'is_service': service,
      'is_featured': true,
      'is_assembly': false,
      'created_at': _now,
      'product_images': <Object>[],
    };

Map<String, dynamic> _nestedProduct(String id, String name) => {
  'id': id,
  'name': name,
  'sku': 'SKU-$id',
  'cost_price': 600,
  'selling_price': 1000,
  'min_stock': 2,
  'product_images': <Object>[],
};

Map<String, dynamic> _publicProduct(String id, String name) => {
  'id': id,
  'sku': 'SKU-$id',
  'barcode': null,
  'category_id': 'cat-1',
  'name': name,
  'description': 'وصف $name',
  'specs': {'الضمان': 'سنة'},
  'selling_price': 1000,
  'effective_price': 900,
  'is_available': true,
  'created_at': _now,
  'primary_image_url': null,
  'is_featured': true,
};

Map<String, dynamic> _cart() => {
  'items': [
    {
      'product_id': productId,
      'name': 'مكواة بخار',
      'sku': 'SKU-$productId',
      'image_url': null,
      'quantity': 2,
      'unit_price': 1000,
      'price_seen': 1000,
      'price_changed': false,
      'line_total': 2000,
      'is_active': true,
      'is_available': true,
      'option_ids': <Object>[],
      'options': <Object>[],
    },
  ],
  'item_count': 2,
  'subtotal': 2000,
  'currency': 'EGP',
  'has_issues': false,
};

Map<String, Object?> fixtureRpcs() => {
  'rpc_get_auth_settings': {'require_verified_phone': false},
  'rpc_get_support_contact': {'whatsapp': '201000000000'},
  'rpc_get_instapay_details': {
    'configured': true,
    'ipa_address': 'shop@instapay',
    'beneficiary_name': 'المحل',
  },
  'rpc_get_my_wallet': {
    'id': 'w-1',
    'balance': 250,
    'currency': 'EGP',
    'is_active': true,
  },
  'rpc_get_my_cart': _cart(),
  'rpc_effective_prices': [
    {'product_id': productId, 'effective_price': 900},
  ],
  'rpc_browse_products': [
    _publicProduct(productId, 'مكواة بخار'),
    _publicProduct('p-2', 'فلتر مياه'),
  ],
  'rpc_offer_products': [_publicProduct(productId, 'مكواة بخار')],
  'rpc_my_maintenance_position': [
    {'queue_position': 2, 'people_ahead': 1, 'total_active': 3},
  ],
  'rpc_check_service_availability': {
    'available': true,
    'service_area_id': areaId,
    'service_area_name': 'مدينة نصر',
  },
};

Map<String, List<Map<String, dynamic>>> fixtureTables() => {
  'users': [
    for (final (id, role, name) in [
      (adminId, 'admin', 'المدير'),
      (salesId, 'sales', 'موظف المبيعات'),
      (techId, 'technician', 'محمود الفني'),
      (customerId, 'customer', 'أحمد العميل'),
    ])
      {
        'id': id,
        'role': role,
        'full_name': name,
        'phone': '2010000000${id.length}',
        'email': '$role@example.com',
        'avatar_url': null,
        'is_active': true,
        'phone_verified_at': _now,
        'email_verified_at': _now,
        'created_at': _now,
      },
  ],
  'customers': [
    {'id': customerId, 'full_name': 'أحمد العميل', 'phone': '201000000001'},
  ],
  'technicians': [
    {
      'id': techId,
      'employee_code': 'T-01',
      'is_active': true,
      'users': {'full_name': 'محمود الفني'},
    },
  ],
  'product_categories': [
    {
      'id': 'cat-1',
      'parent_id': null,
      'name': 'أجهزة',
      'image_url': null,
      'sort_order': 1,
      'is_active': true,
    },
  ],
  'products': [
    _product(productId, 'مكواة بخار'),
    _product('p-2', 'فلتر مياه'),
    _product('svc', 'صيانة', service: true),
  ],
  'products_public': [
    _publicProduct(productId, 'مكواة بخار'),
    _publicProduct('p-2', 'فلتر مياه'),
  ],
  'product_options': [
    {
      'id': 'opt-1',
      'product_id': productId,
      'name': 'خرطوم إضافي',
      'extra_price': 50,
      'sort_order': 1,
    },
  ],
  'warehouses': [
    {'id': 'wh-1', 'name': 'المخزن الرئيسي'},
  ],
  'warehouse_stock': [
    {'quantity': 8, 'products': _nestedProduct(productId, 'مكواة بخار')},
    {'quantity': 1, 'products': _nestedProduct('p-2', 'فلتر مياه')},
  ],
  'warehouse_stock_value': [
    {'stock_value': 5400},
  ],
  'low_stock_products': [
    {'product_id': 'p-2', 'name': 'فلتر مياه', 'quantity': 1, 'min_stock': 2},
  ],
  'technician_bags': [
    {
      'id': 'bag-1',
      'technician_id': techId,
      'technician_bag_stock': [
        {'quantity': 3, 'products': _nestedProduct(productId, 'مكواة بخار')},
      ],
    },
  ],
  'stock_movements': [
    {
      'id': 'mv-1',
      'movement_number': 12,
      'movement_type': 'purchase',
      'quantity': 5,
      'from_location_type': 'supplier',
      'to_location_type': 'warehouse',
      'unit_cost': 600,
      'total_cost': 3000,
      'notes': null,
      'created_at': _now,
      'products': _nestedProduct(productId, 'مكواة بخار'),
    },
  ],
  'inventory_counts': [
    {
      'id': countId,
      'count_number': 3,
      'status': 'draft',
      'started_at': _now,
      'completed_at': null,
      'notes': null,
    },
  ],
  'inventory_count_items': [
    {
      'id': 'ki-1',
      'count_id': countId,
      'system_quantity': 8,
      'actual_quantity': 7,
      'difference': -1,
      'reason': 'تالف',
      'notes': null,
      'products': _nestedProduct(productId, 'مكواة بخار'),
    },
  ],
  'orders': [
    {
      'id': orderId,
      'order_number': 101,
      'customer_id': customerId,
      'status': 'pending',
      'subtotal': 2000,
      'discount': 0,
      'total': 2050,
      'paid_amount': 0,
      'payment_status': 'unpaid',
      'delivery_address': 'شارع عباس العقاد',
      'delivery_recipient_name': 'أحمد العميل',
      'delivery_phone': '201000000001',
      'delivery_building': '5',
      'delivery_floor': '2',
      'delivery_apartment': '4',
      'delivery_landmark': null,
      'delivery_latitude': 30.05,
      'delivery_longitude': 31.33,
      'delivery_city_id': cityId,
      'delivery_service_area_id': areaId,
      'shipping_fee': 50,
      'shipping_fee_status': 'approved',
      'shipping_fee_rejection_reason': null,
      'notes': null,
      'cancelled_reason': null,
      'created_at': _now,
      'order_items': [
        {
          'quantity': 2,
          'unit_price_snapshot': 1000,
          'unit_cost_snapshot': 600,
          'discount': 0,
        },
      ],
    },
  ],
  'order_items_display': [
    {
      'id': 'oi-1',
      'order_id': orderId,
      'product_id': productId,
      'product_name_snapshot': 'مكواة بخار',
      'quantity': 2,
      'unit_price_snapshot': 1000,
      'discount': 0,
      'line_total': 2000,
      'selected_options_snapshot': <Object>[],
    },
  ],
  'payments': [
    {
      'id': 'pay-1',
      'customer_id': customerId,
      'order_id': orderId,
      'channel': 'instapay',
      'provider': null,
      'amount': 2050,
      'currency': 'EGP',
      'status': 'pending_verification',
      'provider_reference': 'REF123',
      'metadata': {'sender_name': 'أحمد'},
      'created_at': _now,
      'paid_at': null,
    },
  ],
  'maintenance_requests': [
    {
      'id': maintenanceId,
      'ticket_number': 55,
      'customer_id': customerId,
      'customer_name': 'أحمد العميل',
      'phone': '201000000001',
      'address': 'مدينة نصر',
      'latitude': 30.05,
      'longitude': 31.33,
      'device_type': 'غسالة',
      'problem_description': 'لا تعمل',
      'notes': null,
      'status': 'assigned',
      'assigned_technician_id': techId,
      'created_at': _now,
      'assigned_at': _now,
      'started_at': null,
      'completed_at': null,
      'cancelled_at': null,
      'cancelled_reason': null,
    },
  ],
  'sales': [
    {
      'id': saleId,
      'sale_number': 7,
      'technician_id': techId,
      'customer_name': 'عميل محل',
      'customer_phone': null,
      'payment_method': 'cash',
      'subtotal': 1000,
      'discount': 0,
      'total': 1000,
      'paid_amount': 1000,
      'status': 'completed',
      'created_at': _now,
      'sale_items': [
        {
          'quantity': 1,
          'unit_price_snapshot': 1000,
          'unit_cost_snapshot': 600,
          'discount': 0,
        },
      ],
    },
  ],
  'sale_items_display': [
    {
      'id': 'si-1',
      'sale_id': saleId,
      'product_id': productId,
      'product_name_snapshot': 'مكواة بخار',
      'quantity': 1,
      'unit_price_snapshot': 1000,
      'discount': 0,
      'line_total': 1000,
    },
  ],
  'sale_items_with_returns': [
    {
      'id': 'si-1',
      'sale_id': saleId,
      'product_id': productId,
      'product_name_snapshot': 'مكواة بخار',
      'quantity': 1,
      'unit_price_snapshot': 1000,
      'discount': 0,
      'line_total': 1000,
      'returned_quantity': 0,
    },
  ],
  'daily_sales_summary': [
    {'day': _today, 'revenue': 3000, 'cogs': 1800},
  ],
  'cashbox_balances': [
    {'cashbox_id': 'cb-1', 'name': 'الخزنة', 'balance': 12000, 'kind': 'cash'},
    {
      'cashbox_id': 'cb-2',
      'name': 'خزنة التحويلات',
      'balance': 3000,
      'kind': 'transfer',
    },
  ],
  'cash_transactions': [
    {
      'id': 'ct-1',
      'cashbox_id': 'cb-1',
      'transaction_type': 'sale',
      'amount': 1000,
      'reference_type': 'sale',
      'notes': null,
      'created_at': _now,
    },
  ],
  'expense_categories': [
    {'id': 'ec-1', 'name': 'كهرباء', 'is_active': true},
  ],
  'expenses': [
    {
      'id': 'ex-1',
      'expense_number': 4,
      'amount': 300,
      'expense_date': _today,
      'notes': 'فاتورة',
      'created_at': _now,
      'expense_categories': {'name': 'كهرباء'},
    },
  ],
  'customer_account_summary': [
    {
      'customer_id': customerId,
      'customer_name': 'أحمد العميل',
      'total_purchases': 2050,
      'total_paid': 1000,
      'remaining_balance': 1050,
    },
  ],
  'customer_account_transactions': [
    {
      'id': 'ctx-1',
      'customer_id': customerId,
      'transaction_type': 'order_charge',
      'amount': 2050,
      'order_id': orderId,
      'notes': null,
      'created_at': _now,
    },
  ],
  'customer_addresses': [
    {
      'id': 'addr-1',
      'city_id': cityId,
      'service_area_id': areaId,
      'label': 'البيت',
      'recipient_name': 'أحمد العميل',
      'phone': '201000000001',
      'address_line': 'شارع عباس العقاد',
      'building': '5',
      'floor': '2',
      'apartment': '4',
      'landmark': null,
      'latitude': 30.05,
      'longitude': 31.33,
      'is_default': true,
      'is_active': true,
      'created_at': _now,
      'cities': {'name_ar': 'القاهرة'},
      'service_areas': {'name_ar': 'مدينة نصر'},
    },
  ],
  'technician_account_summary': [
    {
      'technician_id': techId,
      'technician_name': 'محمود الفني',
      'bag_value': 3000,
      'total_sales': 1000,
      'total_collected': 500,
      'amount_due': 500,
    },
  ],
  'technician_account_transactions': [
    {
      'id': 'tt-1',
      'technician_id': techId,
      'transaction_type': 'sale_credit',
      'amount': 1000,
      'notes': null,
      'created_at': _now,
    },
  ],
  'technician_supplies': [
    {
      'id': 'sup-1',
      'supply_number': 2,
      'technician_id': techId,
      'amount': 500,
      'status': 'pending',
      'notes': null,
      'rejection_reason': null,
      'created_at': _now,
    },
  ],
  'countries': [
    {'id': 'eg', 'iso_code': 'EG', 'name_ar': 'مصر', 'is_active': true},
  ],
  'cities': [
    {
      'id': cityId,
      'country_id': 'eg',
      'name_ar': 'القاهرة',
      'name_en': 'Cairo',
      'center_latitude': 30.04,
      'center_longitude': 31.24,
      'is_active': true,
      'sort_order': 1,
    },
  ],
  'service_areas': [
    {
      'id': areaId,
      'city_id': cityId,
      'name_ar': 'مدينة نصر',
      'center_latitude': 30.05,
      'center_longitude': 31.33,
      'radius_km': 5,
      'is_active': true,
      'notes': null,
    },
  ],
  'offers': [
    {
      'id': offerId,
      'title': 'عرض الشتاء',
      'subtitle': 'خصومات',
      'description': 'تفاصيل العرض',
      'badge_text': 'خصم',
      'image_url': null,
      'starts_at': null,
      'ends_at': null,
      'is_active': true,
      'sort_order': 1,
      'offer_products': [
        {'product_id': productId},
      ],
    },
  ],
  'offer_products': [
    {'offer_id': offerId, 'product_id': productId, 'offer_price': 900},
  ],
  'home_banners': [
    {
      'id': bannerId,
      'title': 'بانر',
      'image_url': 'https://example.com/b.png',
      'target_type': 'none',
      'target_id': null,
      'starts_at': null,
      'ends_at': null,
      'is_active': true,
      'sort_order': 1,
    },
  ],
  'notifications': [
    {
      'id': 'n-1',
      'user_id': adminId,
      'type': 'order_created',
      'title': 'طلب جديد',
      'body': 'طلب رقم 101',
      'data': {'order_id': orderId},
      'is_read': false,
      'created_at': _now,
    },
  ],
  'audit_logs': [
    {
      'id': 'al-1',
      'actor_id': adminId,
      'users': {'full_name': 'المدير'},
      'action': 'UPDATE',
      'table_name': 'products',
      'record_id': productId,
      'old_data': {'selling_price': 950},
      'new_data': {'selling_price': 1000},
      'created_at': _now,
    },
  ],
  'wallet_summary': [
    {
      'wallet_id': 'w-1',
      'customer_id': customerId,
      'customer_name': 'أحمد العميل',
      'balance': 250,
      'currency': 'EGP',
      'is_active': true,
    },
  ],
  'wallet_liability_summary': [
    {'total_liability': 250, 'wallet_count': 1},
  ],
  'wallet_transactions': [
    {
      'id': 'wt-1',
      'wallet_id': 'w-1',
      'type': 'topup',
      'amount': 250,
      'balance_before': 0,
      'balance_after': 250,
      'notes': null,
      'created_at': _now,
    },
  ],
  'supplier_balances': [
    {
      'supplier_id': 'sp-1',
      'name': 'مورد الأجهزة',
      'phone': '201000000009',
      'total_invoices': 3000,
      'total_paid': 1000,
      'balance': 2000,
      'invoices_count': 1,
    },
  ],
  'purchase_invoices_summary': [
    {
      'id': purchaseId,
      'invoice_number': 9,
      'supplier_id': 'sp-1',
      'supplier_name': 'مورد الأجهزة',
      'supplier_phone': '201000000009',
      'supplier_invoice_ref': 'INV-77',
      'invoice_date': _today,
      'subtotal': 3000,
      'discount': 0,
      'total': 3000,
      'paid_amount': 1000,
      'remaining_amount': 2000,
      'items_count': 1,
      'notes': null,
      'created_at': _now,
    },
  ],
  'purchase_invoice_items': [
    {
      'invoice_id': purchaseId,
      'product_id': productId,
      'product_name_snapshot': 'مكواة بخار',
      'quantity': 5,
      'unit_cost': 600,
      'line_total': 3000,
    },
  ],
  'supplier_payments': [
    {
      'invoice_id': purchaseId,
      'payment_number': 1,
      'amount': 1000,
      'kind': 'cash',
      'notes': null,
      'created_at': _now,
    },
  ],
};
