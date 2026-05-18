import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/staff/contexts/auth_provider.dart';
import 'package:restaurant_unified_app/staff/models/models.dart'
    as staff_models;
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
  UserRole _selectedRole = UserRole.admin;
  bool _obscurePassword = true;
  String? _error;
  String _restaurantName = 'Restaurant Unified';

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

    try {
      await auth.login(
        _emailController.text,
        _passwordController.text,
        _selectedRole,
      );

      if (_selectedRole != UserRole.admin) {
        if (!mounted) return;
        final staffAuth = context.read<StaffAuthProvider>();
        await staffAuth.login(
          _emailController.text,
          _passwordController.text,
          _selectedRole == UserRole.servingStaff
              ? staff_models.StaffRole.servingStaff
              : staff_models.StaffRole.billingStaff,
        );
      }
      // Navigation will be handled by the router/main redirect logic
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
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

                // Role Selector
                Row(
                  children: [
                    _RoleButton(
                      label: 'Admin',
                      isSelected: _selectedRole == UserRole.admin,
                      onTap: () => setState(
                        () => _selectedRole = UserRole.admin,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoleButton(
                      label: 'Staff',
                      isSelected: _selectedRole != UserRole.admin,
                      onTap: () => setState(
                        () => _selectedRole = UserRole.servingStaff,
                      ),
                    ),
                  ],
                ),

                if (_selectedRole != UserRole.admin) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SubRoleButton(
                          label: 'Serving',
                          isSelected: _selectedRole == UserRole.servingStaff,
                          onTap: () => setState(
                            () => _selectedRole = UserRole.servingStaff,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SubRoleButton(
                          label: 'Billing',
                          isSelected: _selectedRole == UserRole.billingStaff,
                          onTap: () => setState(
                            () => _selectedRole = UserRole.billingStaff,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

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

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.slate200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.sans(
                weight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubRoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubRoleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.slate200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.sans(
              size: 12,
              weight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.goldDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
