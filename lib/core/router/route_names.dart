abstract final class Routes {
  static const splash = '/splash';
  static const configMissing = '/config-missing';
  static const login = '/login';
  static const register = '/register';

  static const adminHome = '/admin';
  static const technicianHome = '/technician';
  static const customerHome = '/customer';

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
}
