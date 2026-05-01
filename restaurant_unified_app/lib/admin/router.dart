import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/admin/screens/landing/admin_landing_screen.dart';
import 'package:restaurant_unified_app/admin/screens/login/admin_login_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/admin_dashboard_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/menu/menu_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/staff/staff_landing_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/staff/staff_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/tables/tables_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/orders/orders_screen.dart';
import 'package:restaurant_unified_app/admin/screens/dashboard/profile/profile_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final loc = state.matchedLocation;
      final isPublicRoute = loc == '/admin' || loc == '/admin/login';

      if (!isLoggedIn && !isPublicRoute) {
        return '/admin/login';
      }
      if (isLoggedIn && loc == '/admin/login') {
        return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminLandingScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      // Staff landing — choose between Serving Staff and Billing Staff
      GoRoute(
        path: '/admin/dashboard/staff',
        builder: (context, state) => const StaffLandingScreen(),
      ),
      // Staff detail screen — role is 'server' or 'cashier'
      GoRoute(
        path: '/admin/dashboard/staff/:role',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'server';
          return StaffScreen(role: role);
        },
      ),
      GoRoute(
        path: '/admin/dashboard/tables',
        builder: (context, state) => const TablesScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
