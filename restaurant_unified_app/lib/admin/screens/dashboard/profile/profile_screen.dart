import 'package:restaurant_unified_app/core/theme.dart';
import 'package:restaurant_unified_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/admin/core/providers/restaurant_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchRestaurant();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final restaurantProv = context.watch<RestaurantProvider>();
    final r = restaurantProv.restaurant;

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
        backgroundColor: AppColors.rubyRed,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: AppColors.gold),
        ),
      ),
      body: restaurantProv.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.rubyRed))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile header card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.rubyRed, AppColors.rubyDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.glow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          Container(
                            width: isMobile ? 48 : 64,
                            height: isMobile ? 48 : 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                            ),
                            child: Icon(Icons.restaurant_rounded,
                                color: Colors.white, size: isMobile ? 24 : 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r?.name ?? 'Restaurant',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  )),
                              Text(r?.restaurantType ?? 'Fine Dining',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 13,
                                    color: AppColors.gold.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          )),
                          if (!isMobile) ...[
                            const SizedBox(width: 16),
                            _buildStatusBadge(r),
                          ],
                        ]),
                        if (isMobile) ...[
                          const SizedBox(height: 16),
                          _buildStatusBadge(r),
                        ],
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.05),

                  const SizedBox(height: 24),

                  // ── Restaurant info ────────────────────────────────────────
                  if (r != null) ...[
                    Text('Restaurant Details',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        )),
                    const SizedBox(height: 14),
                    _infoCard([
                      if (r.address != null)
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: r.address!),
                      if (r.city != null)
                        _InfoRow(
                            icon: Icons.location_city_outlined,
                            label: 'City',
                            value: r.city!),
                      if (r.phone != null)
                        _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: r.phone!),
                      if (r.description != null)
                        _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Description',
                            value: r.description!),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // ── Admin info ─────────────────────────────────────────────
                  Text('Admin Account',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      )),
                  const SizedBox(height: 14),
                  _infoCard([
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: auth.userEmail ?? 'admin@restaurant.com',
                    ),
                    const _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: 'Administrator',
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // ── Logout ─────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) context.go('/admin/login');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text('Logout',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge(dynamic r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: r != null && r.isActive
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: r != null && r.isActive
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        r?.status ?? 'UNKNOWN',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: r != null && r.isActive ? AppColors.success : AppColors.warning,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  Icon(row.icon, color: AppColors.rubyRed, size: 20),
                  const SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 2),
                        Text(row.value,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textDark,
                            )),
                      ]),
                ]),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
}


