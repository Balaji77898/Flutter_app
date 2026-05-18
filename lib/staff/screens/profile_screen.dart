import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../contexts/auth_provider.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<StaffAuthProvider>();
    final user = auth.user;
    final role = auth.role;
    final isBilling = role == StaffRole.billingStaff;

    final roleLabel = isBilling ? 'Billing Staff' : 'Serving Staff';
    final accentColor =
        isBilling ? AppColors.billingAccent : AppColors.servingAccent;

    final name = user?.name ?? 'Staff Member';
    final initials = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          // ── Profile Hero Header ──────────────────────────────────────
          _ProfileHeroHeader(
            name: name,
            initials: initials,
            roleLabel: roleLabel,
            accentColor: accentColor,
            isBilling: isBilling,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Personal Details Card ──
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Personal Details',
                              style: AppTextStyles.title(
                                color: AppColors.slate900,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.slate100),
                        const SizedBox(height: 12),
                        _ProfileRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? 'N/A',
                          iconColor: AppColors.info,
                          iconBg: AppColors.infoLight,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          icon: Icons.work_rounded,
                          label: 'Role',
                          value: roleLabel,
                          iconColor: accentColor,
                          iconBg: isBilling
                              ? AppColors.billingAccentLight
                              : AppColors.servingAccentLight,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          icon: Icons.restaurant_rounded,
                          label: 'Restaurant',
                          value: user?.restaurantName ?? 'RestaurantOS',
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        if (user?.phone != null) ...[
                          const SizedBox(height: 14),
                          _ProfileRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: user!.phone!,
                            iconColor: AppColors.success,
                            iconBg: AppColors.successLight,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _ProfileRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Joined On',
                          value: _formatDate(user?.createdAt),
                          iconColor: AppColors.slate500,
                          iconBg: AppColors.slate100,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms).slideY(
                        begin: 0.06,
                        duration: 400.ms,
                        curve: Curves.easeOutQuad,
                      ),

                  const SizedBox(height: 16),

                  // ── Quick Access Card ──
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Quick Access',
                              style: AppTextStyles.title(
                                color: AppColors.slate900,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!isBilling) ...[
                          _QuickLink(
                            icon: Icons.receipt_long_rounded,
                            label: 'View Active Orders',
                            accentColor: AppColors.primary,
                            onTap: () => context.push('/staff/orders'),
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.slate100,
                          ),
                          _QuickLink(
                            icon: Icons.table_restaurant_rounded,
                            label: 'Floor Plan',
                            accentColor: AppColors.billingAccent,
                            onTap: () => context.push('/staff/tables'),
                          ),
                        ] else ...[
                          _QuickLink(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Billing & Payments',
                            accentColor: AppColors.billingAccent,
                            onTap: () => context.push('/staff/billing'),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fade(duration: 400.ms, delay: 80.ms).slideY(
                        begin: 0.06,
                        duration: 400.ms,
                        curve: Curves.easeOutQuad,
                      ),

                  const SizedBox(height: 16),

                  // ── App Info + Logout ──
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RestaurantOS',
                                  style: AppTextStyles.label(
                                    color: AppColors.slate900,
                                    size: 14,
                                  ),
                                ),
                                Text(
                                  'Staff App v1.0.0',
                                  style: AppTextStyles.body(
                                    color: AppColors.slate400,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                isBilling ? 'BILLING' : 'SERVING',
                                style: AppTheme.sans(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: accentColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Full-width logout button
                        GestureDetector(
                          onTap: () async {
                            final navigator = GoRouter.of(context);
                            final rootAuth = context.read<AuthProvider>();
                            await auth.logout();
                            await rootAuth.logout();
                            navigator.go('/login');
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.danger.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sign Out',
                                  style: AppTheme.sans(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms, delay: 160.ms).slideY(
                        begin: 0.06,
                        duration: 400.ms,
                        curve: Curves.easeOutQuad,
                      ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.day} ${_month(now.month)} ${now.year}';
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}

// ─── Profile Hero Header ───────────────────────────────────────────────────
class _ProfileHeroHeader extends StatelessWidget {
  final String name;
  final String initials;
  final String roleLabel;
  final Color accentColor;
  final bool isBilling;

  const _ProfileHeroHeader({
    required this.name,
    required this.initials,
    required this.roleLabel,
    required this.accentColor,
    required this.isBilling,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Gold accent bottom line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accentColor.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Row(
                children: [
                  // Initials Avatar with gold ring
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF9B2C2C),
                              Color(0xFF6B1515),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.8),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTheme.serif(
                              size: 26,
                              weight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      // Online status dot
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        )
                            .animate(
                              onPlay: (c) => c.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.1, 1.1),
                              duration: 1500.ms,
                              curve: Curves.easeInOut,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTheme.serif(
                            size: 22,
                            weight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                roleLabel.toUpperCase(),
                                style: AppTheme.sans(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: accentColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                'ACTIVE NOW',
                                style: AppTheme.sans(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  .animate()
                  .fade(duration: 400.ms)
                  .slideX(begin: -0.05, curve: Curves.easeOutQuad),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Row ───────────────────────────────────────────────────────────
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.overline(
                  color: AppColors.slate400,
                  size: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.label(color: AppColors.slate800, size: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Quick Link ───────────────────────────────────────────────────────────
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label(color: AppColors.slate800, size: 14),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.slate300,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
