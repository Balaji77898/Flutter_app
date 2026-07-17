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
        final mappedRole =
            staffUser.role == staff_models.StaffRole.servingStaff
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

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _restaurantName,
                  style: AppTheme.serif(
                    size: 28,
                    weight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your dashboard',
                  style: AppTheme.sans(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),

                

                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fade(duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9)),
        ),
      ),
    );
  }
}

