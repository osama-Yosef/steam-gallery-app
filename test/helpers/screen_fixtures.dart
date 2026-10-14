import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';

import 'fake_backend.dart';
import 'screen_data.dart';

const adminId = 'u-admin';
const salesId = 'u-sales';
const techId = 'u-tech';
const customerId = 'u-cust';

const productId = 'p-1';
const orderId = 'o-1';
const maintenanceId = 'm-1';
const saleId = 's-1';
const purchaseId = 'pi-1';
const countId = 'k-1';
const cityId = 'c-1';
const areaId = 'a-1';
const offerId = 'of-1';
const bannerId = 'b-1';
const employeeId = 'e-1';

typedef Screen = ({AppRole role, String location});

/// Every screen of the app, by the route that opens it.
const List<Screen> screens = [
  // Admin
  (role: AppRole.admin, location: '/admin'),
  (role: AppRole.admin, location: '/admin/sections'),
  (role: AppRole.admin, location: '/admin/walk-in-sale'),
  (role: AppRole.admin, location: '/admin/walk-in-sale?tab=invoices'),
  (role: AppRole.admin, location: '/admin/month-sales'),
  (role: AppRole.admin, location: '/admin/sync'),
  (role: AppRole.admin, location: '/admin/instapay'),
  (role: AppRole.admin, location: '/admin/sales-returns'),
  (role: AppRole.admin, location: '/admin/sales-returns/$saleId'),
  (role: AppRole.admin, location: '/admin/reports'),
  (role: AppRole.admin, location: '/admin/reports/sales'),
  (role: AppRole.admin, location: '/admin/reports/profit'),
  (role: AppRole.admin, location: '/admin/reports/orders_profit'),
  (role: AppRole.admin, location: '/admin/reports/expenses'),
  (role: AppRole.admin, location: '/admin/reports/inventory'),
  (role: AppRole.admin, location: '/admin/reports/technicians'),
  (role: AppRole.admin, location: '/admin/reports/customers'),
  (role: AppRole.admin, location: '/admin/dashboard'),
  (role: AppRole.admin, location: '/admin/wallets'),
  (role: AppRole.admin, location: '/admin/customers'),
  (role: AppRole.admin, location: '/admin/customers/$customerId'),
  (role: AppRole.admin, location: '/admin/customers/$customerId/payment'),
  (role: AppRole.admin, location: '/admin/marketing'),
  (role: AppRole.admin, location: '/admin/marketing/offers/new'),
  (role: AppRole.admin, location: '/admin/marketing/offers/$offerId'),
  (role: AppRole.admin, location: '/admin/marketing/banners/new'),
  (role: AppRole.admin, location: '/admin/marketing/banners/$bannerId'),
  (role: AppRole.admin, location: '/admin/service-areas'),
  (role: AppRole.admin, location: '/admin/service-areas/new-city'),
  (role: AppRole.admin, location: '/admin/service-areas/$cityId'),
  (role: AppRole.admin, location: '/admin/service-areas/$cityId/new'),
  (role: AppRole.admin, location: '/admin/service-areas/$cityId/$areaId'),
  (role: AppRole.admin, location: '/admin/users'),
  (role: AppRole.admin, location: '/admin/users/new-technician'),
  (role: AppRole.admin, location: '/admin/audit-log'),
  (role: AppRole.admin, location: '/admin/products'),
  (role: AppRole.admin, location: '/admin/products/new'),
  (role: AppRole.admin, location: '/admin/products/price-list'),
  (role: AppRole.admin, location: '/admin/products/$productId/edit'),
  (role: AppRole.admin, location: '/admin/categories'),
  (role: AppRole.admin, location: '/admin/orders'),
  (role: AppRole.admin, location: '/admin/orders/history'),
  (role: AppRole.admin, location: '/admin/orders/$orderId'),
  (role: AppRole.admin, location: '/admin/maintenance'),
  (role: AppRole.admin, location: '/admin/maintenance/history'),
  (role: AppRole.admin, location: '/admin/maintenance/$maintenanceId'),
  (role: AppRole.admin, location: '/admin/warehouse'),
  (role: AppRole.admin, location: '/admin/warehouse/purchases'),
  (role: AppRole.admin, location: '/admin/warehouse/purchases/new'),
  (role: AppRole.admin, location: '/admin/warehouse/purchases/$purchaseId'),
  (role: AppRole.admin, location: '/admin/warehouse/suppliers'),
  (role: AppRole.admin, location: '/admin/warehouse/issue'),
  (role: AppRole.admin, location: '/admin/warehouse/movements'),
  (role: AppRole.admin, location: '/admin/warehouse/bags'),
  (role: AppRole.admin, location: '/admin/warehouse/bags/$techId'),
  (role: AppRole.admin, location: '/admin/warehouse/counts'),
  (role: AppRole.admin, location: '/admin/warehouse/counts/$countId'),
  (role: AppRole.admin, location: '/admin/technicians/$techId/account'),
  (role: AppRole.admin, location: '/admin/technicians/$techId/account/supply'),
  (role: AppRole.admin, location: '/admin/technicians/$techId/account/history'),
  (role: AppRole.admin, location: '/admin/cashbox'),
  (role: AppRole.admin, location: '/admin/expenses'),
  (role: AppRole.admin, location: '/admin/expenses/new'),
  (role: AppRole.admin, location: '/admin/cashbox/deposit'),
  (role: AppRole.admin, location: '/admin/cashbox/withdraw'),
  (role: AppRole.admin, location: '/admin/cashbox/transfer'),
  (role: AppRole.admin, location: '/admin/expenses/categories'),
  (role: AppRole.admin, location: '/admin/warehouse/opening-stock'),
  (role: AppRole.admin, location: '/admin/employees'),
  (role: AppRole.admin, location: '/admin/employees/new'),
  (role: AppRole.admin, location: '/admin/employees/attendance'),
  (role: AppRole.admin, location: '/admin/employees/$employeeId'),
  (role: AppRole.admin, location: '/admin/employees/$employeeId/edit'),
  (role: AppRole.admin, location: '/notifications'),
  // Sales
  (role: AppRole.sales, location: '/sales'),
  (role: AppRole.sales, location: '/sales/orders'),
  (role: AppRole.sales, location: '/sales/orders/history'),
  (role: AppRole.sales, location: '/sales/orders/$orderId'),
  (role: AppRole.sales, location: '/sales/sections'),
  (role: AppRole.sales, location: '/sales/sections/marketing'),
  (role: AppRole.sales, location: '/sales/sections/instapay'),
  (role: AppRole.sales, location: '/sales/sections/sales-returns'),
  (role: AppRole.sales, location: '/sales/sections/cashbox'),
  (role: AppRole.sales, location: '/sales/sections/cashbox/expenses'),
  (role: AppRole.sales, location: '/sales/sections/cashbox/transfer'),
  (role: AppRole.sales, location: '/sales/sale'),
  (role: AppRole.sales, location: '/sales/invoices'),
  (role: AppRole.sales, location: '/sales/month-sales'),
  (role: AppRole.sales, location: '/sales/today-expenses'),
  (role: AppRole.sales, location: '/sales/low-stock'),
  (role: AppRole.sales, location: '/sales/sections/warehouse'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/purchases'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/purchases/new'),
  (
    role: AppRole.sales,
    location: '/sales/sections/warehouse/purchases/$purchaseId',
  ),
  (role: AppRole.sales, location: '/sales/sections/warehouse/suppliers'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/issue'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/opening-stock'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/movements'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/bags'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/bags/$techId'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/counts'),
  (role: AppRole.sales, location: '/sales/sections/warehouse/counts/$countId'),
  (role: AppRole.sales, location: '/sales/sections/technicians/$techId/account'),
  (
    role: AppRole.sales,
    location: '/sales/sections/technicians/$techId/account/supply',
  ),
  (
    role: AppRole.sales,
    location: '/sales/sections/technicians/$techId/account/history',
  ),
  (role: AppRole.sales, location: '/sales/sections/products'),
  (role: AppRole.sales, location: '/sales/sections/products/new'),
  (role: AppRole.sales, location: '/sales/sections/products/price-list'),
  (role: AppRole.sales, location: '/sales/sections/products/$productId/edit'),
  (role: AppRole.sales, location: '/sales/sections/categories'),
  (role: AppRole.sales, location: '/sales/sections/employees'),
  (role: AppRole.sales, location: '/sales/sections/employees/new'),
  (role: AppRole.sales, location: '/sales/sections/employees/attendance'),
  (role: AppRole.sales, location: '/sales/sections/employees/$employeeId'),
  (role: AppRole.sales, location: '/sales/sections/employees/$employeeId/edit'),
  (role: AppRole.sales, location: '/sales/sections/customers'),
  (role: AppRole.sales, location: '/sales/sections/customers/$customerId'),
  (
    role: AppRole.sales,
    location: '/sales/sections/customers/$customerId/payment',
  ),
  (role: AppRole.sales, location: '/sales/sections/wallets'),
  // Technician
  (role: AppRole.technician, location: '/technician'),
  (
    role: AppRole.technician,
    location: '/technician/maintenance/$maintenanceId',
  ),
  (role: AppRole.technician, location: '/technician/bag'),
  (role: AppRole.technician, location: '/technician/bag/sell'),
  (role: AppRole.technician, location: '/technician/bag/sales'),
  (role: AppRole.technician, location: '/technician/bag/sales/$saleId'),
  (role: AppRole.technician, location: '/technician/account'),
  (role: AppRole.technician, location: '/technician/account/supply'),
  (role: AppRole.technician, location: '/technician/account/history'),
  // Customer
  (role: AppRole.customer, location: '/customer'),
  (role: AppRole.customer, location: '/customer/store'),
  (role: AppRole.customer, location: '/customer/product/$productId'),
  (role: AppRole.customer, location: '/customer/offers/$offerId'),
  (role: AppRole.customer, location: '/customer/maintenance'),
  (role: AppRole.customer, location: '/customer/maintenance/new'),
  (role: AppRole.customer, location: '/customer/maintenance/$maintenanceId'),
  (role: AppRole.customer, location: '/customer/cart'),
  (role: AppRole.customer, location: '/customer/checkout'),
  (role: AppRole.customer, location: '/customer/orders'),
  (role: AppRole.customer, location: '/customer/orders/$orderId'),
  (role: AppRole.customer, location: '/customer/orders/$orderId/instapay'),
  (role: AppRole.customer, location: '/customer/account'),
  (role: AppRole.customer, location: '/customer/account/addresses'),
  (role: AppRole.customer, location: '/customer/account/addresses/new'),
  (role: AppRole.customer, location: '/customer/account/wallet'),
  (role: AppRole.customer, location: '/customer/account/wallet/topup'),
];

/// A small shop's worth of data: one or two rows in every table and view the
/// screens read, all pointing at each other by the ids above.
FakeBackend fixtureBackend() =>
    FakeBackend(tables: fixtureTables(), rpcs: fixtureRpcs());
