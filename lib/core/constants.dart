import 'package:flutter/material.dart';

// ─── Backend Base URL ───────────────────────────────────────────────────────
const String kBackendBase = 'https://pos-backend-s380.onrender.com';

// ─── API Endpoints ───────────────────────────────────────────────────────────
class ApiEndpoints {
  static const String login = '/api/auth/login';
  static const String adminLogin = '/api/admin/login';
  static const String staffLogin = '/api/staff/login';
  static const String me = '/api/admin/me';
  
  // Admin Endpoints
  static const String restaurant = '/api/admin/restaurant';
  static const String staffList = '/api/admin/staff';
  static String staffById(String id) => '/api/admin/staff/$id';
  static String toggleStaff(String id) => '/api/admin/staff/$id/toggle';
  
  static const String tablesList = '/api/admin/tables';
  static String tableById(String id) => '/api/admin/tables/$id';
  static String toggleTable(String id) => '/api/admin/tables/$id/toggle';
  static String deleteTable(String id) => '/api/admin/tables/$id';
  
  static const String menuCategoriesList = '/api/admin/menu/categories';
  static String menuCategoryById(String id) => '/api/admin/menu/categories/$id';
  
  static const String menuItemsList = '/api/admin/menu/items';
  static String menuItemById(String id) => '/api/admin/menu/items/$id';
  static String toggleMenuItem(String id) => '/api/admin/menu/items/$id/toggle';
  
  static const String ordersList = '/api/admin/orders';
  static String orderById(String id) => '/api/admin/orders/$id';
  
  // Staff Endpoints
  static const String staffOrders = '/api/admin/orders';
  static const String staffTables = '/api/admin/tables';
}

// ─── Token / Storage Keys ────────────────────────────────────────────────────
const String kTokenKey = 'auth_token';
const String kUserKey = 'user_data';
const String kRoleKey = 'user_role';

// ─── Enums ───────────────────────────────────────────────────────────────────
enum UserRole { admin, servingStaff, billingStaff }
enum StaffRole { servingStaff, billingStaff }

// ─── Colors ──────────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF5C1020);
  static const Color primaryLight = Color(0xFFA63434);
  static const Color primaryDark = Color(0xFF1A0A06);
  static const Color gold = Color(0xFFC09020);
  static const Color goldLight = Color(0xFFFFD75E);
  static const Color goldDark = Color(0xFFD9A820);
  static const Color ivory = Color(0xFFFAF4E8);
  static const Color ivoryDark = Color(0xFFF1E6D2);
  
  static const Color rubyRed = Color(0xFF7B1D2A);
  static const Color rubyDark = Color(0xFF5C1020);

  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  static const Color servingAccent = Color(0xFFF4C430);
  static const Color servingAccentLight = Color(0xFFFEF9C3);
  static const Color billingAccent = Color(0xFF0D9488);
  static const Color billingAccentLight = Color(0xFFCCFBF1);

  static const Color white = Colors.white;
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
}
