import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_unified_app/core/constants.dart';

class WelcomeScreen extends StatefulWidget {
  final String? tableNumber;

  const WelcomeScreen({super.key, this.tableNumber});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isSaving = true;
  String? _savedTable;

  @override
  void initState() {
    super.initState();
    _saveTableInfo();
  }

  Future<void> _saveTableInfo() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('WelcomeScreen: Received tableNumber: ${widget.tableNumber}');

    if (widget.tableNumber != null && widget.tableNumber!.isNotEmpty) {
      await prefs.setString('tableNumber', widget.tableNumber!);
      _savedTable = widget.tableNumber;
      debugPrint(
        'WelcomeScreen: Saved tableNumber to SharedPreferences: $_savedTable',
      );
    } else {
      // Try to read previously saved table
      _savedTable = prefs.getString('tableNumber');
      debugPrint(
        'WelcomeScreen: Loaded tableNumber from SharedPreferences: $_savedTable',
      );
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.rubyDark, Color(0xFF8B1A2A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Restaurant icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: AppColors.gold,
                    size: 64,
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fadeIn(),

                const SizedBox(height: 32),

                Text(
                  'Welcome!',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                const SizedBox(height: 8),

                Text(
                  'Scan. Order. Enjoy.',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // Table badge
                if (_savedTable != null && !_isSaving)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.table_restaurant,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Table #$_savedTable',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale()
                else if (!_isSaving)
                  Text(
                    'Please scan a table QR code\nto start ordering',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                const Spacer(flex: 3),

                // CTA Button
                if (!_isSaving)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savedTable != null
                          ? () => context.go('/customer/menu')
                          : null,
                      icon: const Icon(Icons.restaurant_menu, size: 22),
                      label: Text(
                        _savedTable != null
                            ? 'VIEW MENU & ORDER'
                            : 'NO TABLE SELECTED',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _savedTable != null
                            ? AppColors.gold
                            : Colors.white24,
                        foregroundColor: AppColors.rubyDark,
                        disabledForegroundColor: Colors.white38,
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _savedTable != null ? 8 : 0,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.4),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
