import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/audit_log/presentation/screens/admin_audit_log_screen.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cashbox/presentation/screens/admin/admin_cashbox_screen.dart';
import '../../features/cashbox/presentation/screens/admin/admin_expenses_list_screen.dart';
import '../../features/cashbox/presentation/screens/admin/admin_cash_movement_screen.dart';
import '../../features/cashbox/presentation/screens/admin/admin_record_expense_screen.dart';
import '../../features/customer_account/presentation/screens/admin/admin_customer_account_detail_screen.dart';
import '../../features/customer_account/presentation/screens/admin/admin_customer_payment_screen.dart';
import '../../features/customer_account/presentation/screens/admin/admin_customers_list_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/home/presentation/screens/admin_home_screen.dart';
import '../../features/home/presentation/screens/customer_account_screen.dart';
import '../../features/inventory/presentation/screens/admin/admin_issue_stock_screen.dart';
import '../../features/inventory/presentation/screens/admin/admin_receive_purchase_screen.dart';
import '../../features/inventory/presentation/screens/admin/admin_stock_movements_screen.dart';
import '../../features/inventory/presentation/screens/admin/admin_technician_bag_detail_screen.dart';
import '../../features/inventory/presentation/screens/admin/admin_technician_bag_list_screen.dart';
import '../../features/inventory/presentation/screens/admin/admin_warehouse_screen.dart';
import '../../features/inventory/presentation/screens/technician/technician_bag_screen.dart';
import '../../features/inventory_count/presentation/screens/admin/admin_inventory_count_detail_screen.dart';
import '../../features/inventory_count/presentation/screens/admin/admin_inventory_counts_list_screen.dart';
import '../../features/maintenance/presentation/screens/admin/admin_maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/screens/admin/admin_maintenance_list_screen.dart';
import '../../features/maintenance/presentation/screens/customer/customer_maintenance_home_screen.dart';
import '../../features/maintenance/presentation/screens/customer/maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/screens/customer/new_maintenance_request_screen.dart';
import '../../features/maintenance/presentation/screens/technician/technician_maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/screens/technician/technician_queue_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/admin/admin_order_detail_screen.dart';
import '../../features/orders/presentation/screens/admin/admin_orders_list_screen.dart';
import '../../features/orders/presentation/screens/customer/checkout_screen.dart';
import '../../features/orders/presentation/screens/customer/customer_order_detail_screen.dart';
import '../../features/orders/presentation/screens/customer/customer_orders_list_screen.dart';
import '../../features/products/presentation/screens/admin/admin_category_list_screen.dart';
import '../../features/products/presentation/screens/admin/admin_product_form_screen.dart';
import '../../features/products/presentation/screens/admin/admin_product_list_screen.dart';
import '../../features/products/presentation/screens/customer/customer_catalog_screen.dart';
import '../../features/products/presentation/screens/customer/product_detail_screen.dart';
import '../../features/reports/presentation/screens/admin_report_detail_screen.dart';
import '../../features/reports/presentation/screens/admin_reports_home_screen.dart';
import '../../features/sales/presentation/screens/admin/admin_walk_in_sale_screen.dart';
import '../../features/technician_account/presentation/screens/technician/technician_account_history_screen.dart';
import '../../features/technician_account/presentation/screens/technician/technician_account_screen.dart';
import '../../features/technician_account/presentation/screens/technician/technician_sale_detail_screen.dart';
import '../../features/technician_account/presentation/screens/technician/technician_sale_screen.dart';
import '../../features/technician_account/presentation/screens/technician/technician_sales_list_screen.dart';
import '../../features/technician_account/presentation/screens/technician/technician_supply_screen.dart';
import '../../features/users_admin/presentation/screens/admin_create_user_screen.dart';
import '../../features/users_admin/presentation/screens/admin_users_list_screen.dart';
import '../config/env.dart';
import '../navigation/admin_shell.dart';
import '../navigation/customer_shell.dart';
import '../navigation/technician_shell.dart';
import '../screens/config_missing_screen.dart';
import '../supabase/supabase_client_provider.dart';
import 'go_router_refresh_stream.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Must be checked BEFORE touching supabaseClientProvider at all: without
  // --dart-define values, Supabase.initialize() was never called in main(),
  // so Supabase.instance.client throws. This is the only router the app
  // builds until real credentials are supplied (Module 0 bootstrap).
  if (!Env.isConfigured) {
    return GoRouter(
      initialLocation: Routes.configMissing,
      routes: [
        GoRoute(
          path: Routes.configMissing,
          builder: (_, _) => const ConfigMissingScreen(),
        ),
      ],
    );
  }

  final refreshStream = GoRouterRefreshStream(
    ref.watch(supabaseClientProvider).auth.onAuthStateChange,
  );
  ref.onDispose(refreshStream.dispose);

  // A raw auth event alone isn't enough: currentUserProfileProvider keeps
  // fetching asynchronously AFTER the SIGNED_IN event already fired, and
  // nothing else tells go_router to re-run redirect once that resolves —
  // without this, the app gets stuck on the splash screen forever right
  // after sign-in/sign-up.
  ref.listen(currentUserProfileProvider, (_, _) => refreshStream.ping());

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      final session = ref.read(supabaseClientProvider).auth.currentSession;
      final onAuthScreen = loc == Routes.login || loc == Routes.register;

      if (session == null) {
        return onAuthScreen ? null : Routes.login;
      }

      // Signed in: figure out the role to pick the right shell.
      final profileAsync = ref.read(currentUserProfileProvider);

      // A cached profile (even while a background refetch is in flight —
      // e.g. after ref.invalidate(currentUserProfileProvider) on profile
      // edit) means routing is already settled: bouncing through splash
      // here would remount the current StatefulShellRoute while the old
      // instance hasn't finished disposing, crashing with "Duplicate
      // GlobalKey<StatefulNavigationShellState>". Only the very first,
      // truly-unloaded fetch should route through splash.
      final cachedUser = profileAsync.value;
      if (cachedUser != null) {
        if (onAuthScreen || loc == Routes.splash) {
          return _homeFor(cachedUser.role);
        }
        return null;
      }

      return profileAsync.when(
        data: (user) {
          if (user == null) {
            // handle_new_auth_user() trigger may still be provisioning the
            // row right after sign-up — stay on splash briefly, it retries
            // automatically because authStateChanges keeps refreshing.
            return loc == Routes.splash ? null : Routes.splash;
          }
          if (onAuthScreen || loc == Routes.splash) return _homeFor(user.role);
          return null;
        },
        loading: () => loc == Routes.splash ? null : Routes.splash,
        error: (_, _) => Routes.login,
      );
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.configMissing,
        builder: (_, _) => const ConfigMissingScreen(),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),

      // Admin — persistent glass sidebar, branch order matches AdminShell._items.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminHome,
                builder: (_, _) => const AdminHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'walk-in-sale',
                    builder: (_, _) => const AdminWalkInSaleScreen(),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (_, _) => const AdminReportsHomeScreen(),
                    routes: [
                      GoRoute(
                        path: ':type',
                        builder: (_, state) => AdminReportDetailScreen(
                          reportType: state.pathParameters['type']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'dashboard',
                    builder: (_, _) => const AdminDashboardScreen(),
                  ),
                  GoRoute(
                    path: 'customers',
                    builder: (_, _) => const AdminCustomersListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => AdminCustomerAccountDetailScreen(
                          customerId: state.pathParameters['id']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'payment',
                            builder: (_, state) => AdminCustomerPaymentScreen(
                              customerId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'users',
                    builder: (_, _) => const AdminUsersListScreen(),
                    routes: [
                      GoRoute(
                        path: 'new-technician',
                        builder: (_, _) => const AdminCreateUserScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'audit-log',
                    builder: (_, _) => const AdminAuditLogScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminProducts,
                builder: (_, _) => const AdminProductListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const AdminProductFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (_, state) => AdminProductFormScreen(
                      productId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.adminCategories,
                builder: (_, _) => const AdminCategoryListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminOrders,
                builder: (_, _) => const AdminOrdersListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => AdminOrderDetailScreen(
                      orderId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminMaintenance,
                builder: (_, _) => const AdminMaintenanceListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => AdminMaintenanceDetailScreen(
                      requestId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminWarehouse,
                builder: (_, _) => const AdminWarehouseScreen(),
              ),
              GoRoute(
                path: Routes.adminReceivePurchase,
                builder: (_, _) => const AdminReceivePurchaseScreen(),
              ),
              GoRoute(
                path: Routes.adminIssueStock,
                builder: (_, _) => const AdminIssueStockScreen(),
              ),
              GoRoute(
                path: Routes.adminStockMovements,
                builder: (_, _) => const AdminStockMovementsScreen(),
              ),
              GoRoute(
                path: Routes.adminTechnicianBags,
                builder: (_, _) => const AdminTechnicianBagListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => AdminTechnicianBagDetailScreen(
                      technicianId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.adminInventoryCounts,
                builder: (_, _) => const AdminInventoryCountsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => AdminInventoryCountDetailScreen(
                      countId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/admin/technicians/:id/account',
                builder: (_, state) => TechnicianAccountScreen(
                  technicianId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'supply',
                    builder: (_, state) => TechnicianSupplyScreen(
                      technicianId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (_, state) => TechnicianAccountHistoryScreen(
                      technicianId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminCashbox,
                builder: (_, _) => const AdminCashboxScreen(),
              ),
              GoRoute(
                path: Routes.adminExpenses,
                builder: (_, _) => const AdminExpensesListScreen(),
              ),
              GoRoute(
                path: Routes.adminExpenseNew,
                builder: (_, _) => const AdminRecordExpenseScreen(),
              ),
              GoRoute(
                path: Routes.adminCashDeposit,
                builder: (_, _) => const AdminCashMovementScreen(
                  kind: CashMovementKind.deposit,
                ),
              ),
              GoRoute(
                path: Routes.adminCashWithdraw,
                builder: (_, _) => const AdminCashMovementScreen(
                  kind: CashMovementKind.withdrawal,
                ),
              ),
            ],
          ),
        ],
      ),

      // Technician — floating glass bottom nav, branch order matches
      // TechnicianShell._items.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => TechnicianShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.technicianHome,
                builder: (_, _) => const TechnicianQueueScreen(),
                routes: [
                  GoRoute(
                    path: 'maintenance/:id',
                    builder: (_, state) => TechnicianMaintenanceDetailScreen(
                      requestId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.technicianBag,
                builder: (_, _) => const TechnicianBagScreen(),
                routes: [
                  GoRoute(
                    path: 'sell',
                    // ?maintenance=<id> turns this into the invoice for a
                    // finished job: the same bag-sale form, with the service
                    // fee and fitted parts, linked back to that request.
                    builder: (_, state) => TechnicianSaleScreen(
                      maintenanceRequestId:
                          state.uri.queryParameters['maintenance'],
                      customerName: state.uri.queryParameters['name'],
                      customerPhone: state.uri.queryParameters['phone'],
                    ),
                  ),
                  GoRoute(
                    path: 'sales',
                    builder: (_, _) => const TechnicianSalesListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => TechnicianSaleDetailScreen(
                          saleId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.technicianAccount,
                builder: (_, _) => const TechnicianAccountScreen(),
                routes: [
                  GoRoute(
                    path: 'supply',
                    builder: (_, _) => const TechnicianSupplyScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (_, _) => const TechnicianAccountHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Customer — floating glass bottom nav, branch order matches
      // CustomerShell._items.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => CustomerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerHome,
                builder: (_, _) => const CustomerCatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    builder: (_, state) => ProductDetailScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerMaintenance,
                builder: (_, _) => const CustomerMaintenanceHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const NewMaintenanceRequestScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => MaintenanceDetailScreen(
                      requestId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerCart,
                builder: (_, _) => const CartScreen(),
              ),
              GoRoute(
                path: Routes.customerCheckout,
                builder: (_, _) => const CheckoutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerOrders,
                builder: (_, _) => const CustomerOrdersListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => CustomerOrderDetailScreen(
                      orderId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerAccount,
                builder: (_, _) => const CustomerAccountScreen(),
              ),
            ],
          ),
        ],
      ),
      // Notifications (Module 12) — one shared screen for every role, reachable
      // from the bell icon on any home screen; deliberately outside every
      // shell so it opens full-screen regardless of the current role.
      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
    ],
  );
}

String _homeFor(AppRole role) => switch (role) {
  AppRole.admin => Routes.adminHome,
  AppRole.technician => Routes.technicianHome,
  AppRole.customer => Routes.customerHome,
};
