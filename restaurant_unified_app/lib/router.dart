import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'shared/login_screen.dart';
import 'shared/forgot_password_screen.dart';
import 'shared/reset_password_screen.dart';

// Admin Imports
import 'admin/screens/dashboard/admin_dashboard_screen.dart';
import 'admin/screens/dashboard/menu/menu_screen.dart';
import 'admin/screens/dashboard/staff/staff_landing_screen.dart';
import 'admin/screens/dashboard/staff/staff_screen.dart';
import 'admin/screens/dashboard/tables/tables_screen.dart';
import 'admin/screens/dashboard/orders/orders_screen.dart';
import 'admin/screens/dashboard/profile/profile_screen.dart';

// Staff Imports
import 'staff/screens/main_scaffold.dart';
import 'staff/screens/new_orders_screen.dart';
import 'staff/screens/create_order_screen.dart';
import 'staff/screens/order_details_screen.dart';
import 'staff/screens/payment_screen.dart';
import 'staff/screens/bill_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isResetPassword = state.matchedLocation.startsWith('/reset-password');
      final isAuthRoute = isLoggingIn || isForgotPassword || isResetPassword;
      final isRoot = state.matchedLocation == '/';

      if (!isLoggedIn) {
        if (isAuthRoute) return null;
        return '/login';
      }

      if (isAuthRoute || isRoot) {
        final role = authProvider.role;
        if (role == UserRole.admin) {
          return '/admin/dashboard';
        } else if (role == UserRole.billingStaff || role == UserRole.servingStaff) {
          return role == UserRole.billingStaff ? '/staff/billing' : '/staff/dashboard';
        } else {
          // If logged in but no role (shouldn't happen with fixed loadAuth), go to login
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const UnifiedLoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/admin/staff',
        builder: (context, state) => const StaffLandingScreen(),
      ),
      GoRoute(
        path: '/admin/staff/:role',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'server';
          return StaffScreen(role: role);
        },
      ),
      GoRoute(
        path: '/admin/tables',
        builder: (context, state) => const TablesScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Staff Routes
      GoRoute(
        path: '/staff/dashboard',
        builder: (context, state) => const MainScaffold(initialTab: 0),
      ),
      GoRoute(
        path: '/staff/orders',
        builder: (context, state) => const MainScaffold(initialTab: 1),
      ),
      GoRoute(
        path: '/staff/tables',
        builder: (context, state) => const MainScaffold(initialTab: 2),
      ),
      GoRoute(
        path: '/staff/profile',
        builder: (context, state) => const MainScaffold(initialTab: 3),
      ),
      GoRoute(
        path: '/staff/billing',
        builder: (context, state) => const MainScaffold(initialTab: 0),
      ),
      GoRoute(
        path: '/staff/new-orders',
        builder: (context, state) => const NewOrdersScreen(),
      ),
      GoRoute(
        path: '/staff/create-order',
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: '/staff/order-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDetailsScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/staff/payment/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PaymentScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/staff/bill',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BillScreen(
            orderId: extra['orderId'] as String? ?? '',
            tipAmount: extra['tipAmount'] as int? ?? 0,
            finalTotal: extra['finalTotal'] as int? ?? 0,
            paymentMethod: extra['paymentMethod'] as String? ?? 'cash',
          );
        },
      ),
    ],
  );
}
