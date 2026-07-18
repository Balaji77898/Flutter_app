import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/staff/contexts/auth_provider.dart';
import 'package:restaurant_unified_app/staff/models/models.dart'
    as staff_models;
import 'package:restaurant_unified_app/core/models/user.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;
  String _restaurantName = 'PUREDINE';

  @override
  void initState() {
    super.initState();
    _loadRestaurantName();
  }

  Future<void> _loadRestaurantName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_restaurant_name');
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _restaurantName = cached;
        });
      }
    } catch (e) {
      debugPrint("Error loading cached restaurant name: $e");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _error = null);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    final auth = context.read<AuthProvider>();
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      // 1. Try existing Admin login first
      await auth.login(email, password);
      // Success -> AuthProvider is authenticated with role = admin
      // Router redirect logic sends the user to /admin/dashboard
    } catch (adminError) {
      // 2. Admin login failed -> automatically try existing Staff login
      if (!mounted) return;
      final staffAuth = context.read<StaffAuthProvider>();

      try {
        await staffAuth.login(email, password);
        debugPrint("Role from StaffAuthProvider: ${staffAuth.user?.role}");
        debugPrint("========== STAFF LOGIN ==========");
        debugPrint("Token: ${staffAuth.token}");
        debugPrint("User: ${staffAuth.user?.name}");
        debugPrint("Role: ${staffAuth.user?.role}");

        final staffUser = staffAuth.user;
        if (staffUser == null || staffAuth.token == null) {
          throw Exception('Invalid email or password');
        }

        // Backend already returned the role inside StaffUser.fromJson().
        // Mirror it into AuthProvider so the router (which only listens
        // to AuthProvider) redirects to the correct dashboard.
        final mappedRole = staffUser.role == staff_models.StaffRole.servingStaff
            ? UserRole.servingStaff
            : UserRole.billingStaff;

        await auth.setAuth(
          staffAuth.token!,
          UserProfile(
            id: staffUser.id,
            name: staffUser.name,
            email: staffUser.email,
            role: mappedRole,
            phone: staffUser.phone,
            restaurantName: staffUser.restaurantName,
            createdAt: staffUser.createdAt,
          ),
        );
        // Navigation will be handled by the router/main redirect logic
      } catch (staffError) {
        setState(() => _error = 'Invalid email or password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Column(
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 90),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -20,
                      right: -30,
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 160,
                        color: AppColors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.goldLight,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _restaurantName,
                          textAlign: TextAlign.center,
                          style: AppTheme.serif(
                            size: 30,
                            weight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Access your dashboard',
                          style: AppTheme.sans(
                            color: AppColors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card, overlapping the header
              Transform.translate(
                offset: const Offset(0, -56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: AppShadows.float,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: AppTheme.serif(
                            size: 20,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          style: AppTheme.sans(
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot Password?',
                              style: AppTheme.sans(
                                color: AppColors.primary,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(duration: 500.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
