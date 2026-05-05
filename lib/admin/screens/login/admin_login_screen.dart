import 'package:restaurant_unified_app/core/models/user.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/admin/services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMsg;
  bool _isNetworkError = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _isNetworkError = false;
    });

    try {
      final result = await AuthService.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.setAuth(
        result['token'] as String,
        UserProfile.fromJson(result['user'] as Map<String, dynamic>, UserRole.admin),
      );
      // GoRouter's refreshListenable picks up the auth change and
      // redirects to /admin/dashboard automatically — no manual push needed.
    } on TimeoutException {
      setState(() {
        _isNetworkError = true;
        _errorMsg =
            'Server is waking up (cold start). Please wait a moment and tap "Retry".';
      });
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      final isNetwork = msg.toLowerCase().contains('failed to fetch') ||
          msg.toLowerCase().contains('connection') ||
          msg.toLowerCase().contains('socket') ||
          msg.toLowerCase().contains('network');
      setState(() {
        _isNetworkError = isNetwork;
        _errorMsg = isNetwork
            ? 'Cannot reach server. The server may be waking up — wait 30 seconds and tap "Retry".'
            : msg;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4B0F0F),
              Color(0xFF8B1D1D),
              Color(0xFF6B1515),
            ],
          ),
        ),
        child: Stack(
          children: [
            // decorative watermark
            Positioned(
              right: -60,
              top: -40,
              child: Text('R',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 400,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.03),
                  )),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 0 : 24,
                    vertical: 32,
                  ),
                  child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBrandingPanel(),
        const SizedBox(width: 64),
        SizedBox(width: 420, child: _buildLoginCard()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildBrandingPanel(compact: true),
        const SizedBox(height: 32),
        _buildLoginCard(),
      ],
    );
  }

  Widget _buildBrandingPanel({bool compact = false}) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text('RESTAURANT',
            style: GoogleFonts.playfairDisplaySc(
              fontSize: compact ? 32 : 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 0.9,
            )).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        Text('ADMIN PORTAL',
            style: GoogleFonts.playfairDisplaySc(
              fontSize: compact ? 32 : 56,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFE0B840),
              letterSpacing: 4,
              height: 0.9,
            )).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
        const SizedBox(height: 20),
        if (!compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureRow('📋', 'Order Management'),
              _buildFeatureRow('🪑', 'Table Control'),
              _buildFeatureRow('👨‍🍳', 'Staff Management'),
              _buildFeatureRow('📊', 'Revenue Analytics'),
            ],
          ),
      ],
    );
  }

  Widget _buildFeatureRow(String icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.jost(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              )),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.rubyRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.restaurant_menu,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Welcome Back',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                )),
            Text('Sign in to Admin Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                )),
            const SizedBox(height: 32),

            // Error banner
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isNetworkError
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isNetworkError
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isNetworkError
                              ? Icons.wifi_off_rounded
                              : Icons.error_outline,
                          color: _isNetworkError
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _isNetworkError
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isNetworkError) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text('Retry',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(color: Color(0xFFFBBF24)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Email
            Text('Email',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'admin@restaurant.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password
            Text('Password',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rubyRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Sign In to Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
              ),
            ),
            const SizedBox(height: 16),

            // Back link
            Center(
              child: GestureDetector(
                onTap: () => context.go('/admin'),
                child: Text('← Back to Landing',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.underline,
                    )),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }
}


