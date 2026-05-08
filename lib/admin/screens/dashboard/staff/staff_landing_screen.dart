import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/staff/widgets/common_widgets.dart';

class StaffLandingScreen extends StatelessWidget {
  const StaffLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          // Light Elegant "Foggy" Background
          // Clean Elegant Background
          Positioned.fill(
            child: Container(
              color: AppColors.ivory,
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.05,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=2070&auto=format&fit=crop',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Header (Back Button) ───────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PremiumBackButton(
                            label: 'Back to Dashboard',
                            onTap: () => context.go('/admin/dashboard'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Title Section ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Text(
                              'Staff Management',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.rubyDark,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ).animate().fadeIn().slideY(begin: 0.1),
                            const SizedBox(height: 8),
                            Text(
                              'Select a role to manage credentials and access.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.rubyDark.withOpacity(0.7),
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // ── Cards Section ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Wrap(
                          spacing: 40,
                          runSpacing: 30,
                          alignment: WrapAlignment.center,
                          children: [
                            _StaffTypeCard(
                              title: 'Billing Staff',
                              description:
                                  'Manage cashier terminals and transaction logs.',
                              icon: Icons.receipt_long_rounded,
                              role: 'cashier',
                              index: 0,
                            ),
                            _StaffTypeCard(
                              title: 'Serving Staff',
                              description:
                                  'Manage floor staff and service assignments.',
                              icon: Icons.restaurant_rounded,
                              role: 'server',
                              index: 1,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTypeCard extends StatefulWidget {
  final String title, description, role;
  final IconData icon;
  final int index;

  const _StaffTypeCard({
    required this.title,
    required this.description,
    required this.role,
    required this.icon,
    required this.index,
  });

  @override
  State<_StaffTypeCard> createState() => _StaffTypeCardState();
}

class _StaffTypeCardState extends State<_StaffTypeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/admin/staff/${widget.role}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 320,
          height: 320, // Square like the dashboard
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isHovered ? AppColors.gold : AppColors.rubyDark,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.rubyDark.withOpacity(0.12),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 15 : 10),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon Container ──────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppColors.rubyRed
                      : AppColors.rubyDark.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: _isHovered ? Colors.white : AppColors.rubyDark,
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),
              // ── Title ───────────────────────────────────────────
              Text(
                widget.title,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.rubyDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // ── Description ─────────────────────────────────────
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (widget.index * 200).ms).scale(
              begin: const Offset(0.95, 0.95),
              curve: Curves.easeOutCirc,
            ),
      ),
    );
  }
}
