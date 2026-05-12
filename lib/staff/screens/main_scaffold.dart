import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../contexts/auth_provider.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart' hide AppColors;
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'tables_screen.dart';
import 'billing_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialTab;
  const MainScaffold({super.key, this.initialTab = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final staffAuth = context.watch<StaffAuthProvider>();
    final coreAuth = context.watch<AuthProvider>();

    final role = staffAuth.role;
    final user = staffAuth.user;

    // Fix flicker: Use coreAuth role if staffAuth role is not yet loaded
    final isBilling = role == StaffRole.billingStaff ||
        coreAuth.role == UserRole.billingStaff;

    // Role-based accent color
    final accentColor =
        isBilling ? AppColors.billingAccent : AppColors.servingAccent;
    final accentLightColor =
        isBilling ? AppColors.billingAccentLight : AppColors.servingAccentLight;

    final servingItems = [
      const _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        screen: DashboardScreen(),
      ),
      const _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Orders',
        screen: OrdersScreen(),
      ),
      const _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Tables',
        screen: TablesScreen(),
      ),
      const _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        screen: ProfileScreen(),
      ),
    ];

    final billingItems = [
      const _NavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Billing',
        screen: BillingScreen(),
      ),
      const _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        screen: ProfileScreen(),
      ),
    ];

    final navItems = isBilling ? billingItems : servingItems;
    final safeIndex = _currentIndex < navItems.length ? _currentIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;

        if (isWide) {
          return Scaffold(
            backgroundColor: AppColors.ivory,
            body: Row(
              children: [
                _Sidebar(
                  navItems: navItems,
                  currentIndex: safeIndex,
                  onTap: (idx) => setState(() => _currentIndex = idx),
                  roleName: isBilling ? 'Billing Staff' : 'Serving Staff',
                  isBilling: isBilling,
                  accentColor: accentColor,
                  initials: (user?.name.isNotEmpty == true)
                      ? user!.name.substring(0, 1).toUpperCase()
                      : 'S',
                ),
                Expanded(child: navItems[safeIndex].screen),
              ],
            ),
          );
        }

        // ── Mobile Bottom Navigation ──────────────────────────────────────
        return Scaffold(
          backgroundColor: AppColors.ivory,
          body: navItems[safeIndex].screen,
          bottomNavigationBar: _RoleAwareBottomNav(
            navItems: navItems,
            currentIndex: safeIndex,
            accentColor: accentColor,
            accentLightColor: accentLightColor,
            isBilling: isBilling,
            onTap: (idx) => setState(() => _currentIndex = idx),
          ),
        );
      },
    );
  }
}

// ─── Role-Aware Bottom Navigation Bar ─────────────────────────────────────
class _RoleAwareBottomNav extends StatelessWidget {
  final List<_NavItem> navItems;
  final int currentIndex;
  final Color accentColor;
  final Color accentLightColor;
  final bool isBilling;
  final ValueChanged<int> onTap;

  const _RoleAwareBottomNav({
    required this.navItems,
    required this.currentIndex,
    required this.accentColor,
    required this.accentLightColor,
    required this.isBilling,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: AppShadows.float,
        // Role-specific top border accent
        border: Border(
          top: BorderSide(
            color: accentColor.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: navItems.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final isActive = currentIndex == idx;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with animated pill highlight
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? accentColor.withValues(
                                    alpha: isBilling ? 0.12 : 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: isActive
                                ? Border.all(
                                    color: accentColor.withValues(alpha: 0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive ? accentColor : AppColors.slate400,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: AppTheme.sans(
                            size: 10,
                            weight:
                                isActive ? FontWeight.w800 : FontWeight.w500,
                            color: isActive ? accentColor : AppColors.slate400,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Sidebar for wide screens ──────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String roleName;
  final String initials;
  final bool isBilling;
  final Color accentColor;

  const _Sidebar({
    required this.navItems,
    required this.currentIndex,
    required this.onTap,
    required this.roleName,
    required this.initials,
    required this.isBilling,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.slate100),
        ),
      ),
      child: Column(
        children: [
          // Brand header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.slate100),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'RestaurantOS',
                  style: AppTheme.serif(
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ).copyWith(letterSpacing: -0.5),
                ),
              ],
            ),
          ),

          // Role badge
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isBilling ? 'BILLING STAFF' : 'SERVING STAFF',
                  style: AppTheme.sans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: navItems.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                final isActive = currentIndex == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onTap(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color:
                              isActive ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isActive ? AppShadows.primaryGlow : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.slate500,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: AppTheme.sans(
                                size: 15,
                                weight: isActive
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isActive
                                    ? AppColors.white
                                    : AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom user info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.slate100),
              ),
            ),
            child: Row(
              children: [
                // Initials avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTheme.sans(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleName,
                        style: AppTheme.sans(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Online',
                            style: AppTheme.sans(
                                size: 11, color: AppColors.slate400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
