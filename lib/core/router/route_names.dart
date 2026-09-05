abstract final class Routes {
  static const splash = '/splash';
  static const configMissing = '/config-missing';
  static const login = '/login';
  static const register = '/register';

  static const adminHome = '/admin';
  static const technicianHome = '/technician';
  static const customerHome = '/customer';
  static const customerAccount = '/customer/account';

  // Products & Catalog (Module 2)
  static const adminProducts = '/admin/products';
  static const adminProductNew = '/admin/products/new';
  static const adminCategories = '/admin/categories';
  static String adminProductEdit(String id) => '/admin/products/$id/edit';
  static String customerProductDetail(String id) => '/customer/product/$id';

  // Cart & Orders (Module 3)
  static const customerCart = '/customer/cart';
  static const customerCheckout = '/customer/checkout';
  static const customerOrders = '/customer/orders';
  static String customerOrderDetail(String id) => '/customer/orders/$id';
  static const adminOrders = '/admin/orders';
  static String adminOrderDetail(String id) => '/admin/orders/$id';

  // Maintenance (Module 4)
  static const customerMaintenance = '/customer/maintenance';
  static const customerMaintenanceNew = '/customer/maintenance/new';
  static String customerMaintenanceDetail(String id) =>
      '/customer/maintenance/$id';
  static String technicianMaintenanceDetail(String id) =>
      '/technician/maintenance/$id';
  static const adminMaintenance = '/admin/maintenance';
  static String adminMaintenanceDetail(String id) => '/admin/maintenance/$id';

  // Warehouse & Technician Bag (Module 5)
  static const adminWarehouse = '/admin/warehouse';
  static const adminReceivePurchase = '/admin/warehouse/receive';
  static const adminIssueStock = '/admin/warehouse/issue';
  static const adminStockMovements = '/admin/warehouse/movements';
  static const adminTechnicianBags = '/admin/warehouse/bags';
  static String adminTechnicianBagDetail(String technicianId) =>
      '/admin/warehouse/bags/$technicianId';
  static const technicianBag = '/technician/bag';

  // Technician Sales & Account (Module 6)
  static const technicianBagSell = '/technician/bag/sell';
  static const technicianSales = '/technician/bag/sales';
  static String technicianSaleDetail(String id) => '/technician/bag/sales/$id';
  static const technicianAccount = '/technician/account';
  static const technicianAccountSupply = '/technician/account/supply';
  static const technicianAccountHistory = '/technician/account/history';
  static String adminTechnicianAccount(String technicianId) =>
      '/admin/technicians/$technicianId/account';
  static String adminTechnicianAccountSupply(String technicianId) =>
      '/admin/technicians/$technicianId/account/supply';
  static String adminTechnicianAccountHistory(String technicianId) =>
      '/admin/technicians/$technicianId/account/history';

  // Cashbox & Expenses (Module 7)
  static const adminCashbox = '/admin/cashbox';
  static const adminExpenses = '/admin/expenses';
  static const adminExpenseNew = '/admin/expenses/new';

  // Walk-in sales
  static const adminWalkInSale = '/admin/walk-in-sale';

  // Customer Accounts (Module 8)
  static const adminCustomers = '/admin/customers';
  static String adminCustomerDetail(String customerId) =>
      '/admin/customers/$customerId';
  static String adminCustomerPayment(String customerId) =>
      '/admin/customers/$customerId/payment';

  // Inventory Count (Module 9)
  static const adminInventoryCounts = '/admin/warehouse/counts';
  static String adminInventoryCountDetail(String countId) =>
      '/admin/warehouse/counts/$countId';

  // Dashboard (Module 10)
  static const adminDashboard = '/admin/dashboard';

  // Reports (Module 11)
  static const adminReports = '/admin/reports';
  static String adminReportDetail(String type) => '/admin/reports/$type';

  // Notifications (Module 12) — shared shell for every role
  static const notifications = '/notifications';

  // Users & Roles (Module 13)
  static const adminUsers = '/admin/users';
  static const adminUserNewTechnician = '/admin/users/new-technician';
  static String adminUserDetail(String userId) => '/admin/users/$userId';

  // Audit Log (Module 14)
  static const adminAuditLog = '/admin/audit-log';
}
