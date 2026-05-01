import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/core/theme.dart';
import '../models/models.dart';
import '../contexts/orders_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Staff Form Data
  final _staffIdController = TextEditingController();
  final _staffPasswordController = TextEditingController();
  StaffRole? _selectedRole;

  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _staffIdController.dispose();
    _staffPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _error = null);

    if (_staffIdController.text.isEmpty ||
        _staffPasswordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_selectedRole == null) {
      setState(() => _error = 'Please select a role');
      return;
    }

    final auth = context.read<AuthProvider>();
    final orders = context.read<OrdersProvider>();

    try {
      // 🔥 LOGIN
      await auth.login(
        _staffIdController.text,
        _staffPasswordController.text,
        _selectedRole == StaffRole.billingStaff 
            ? UserRole.billingStaff 
            : UserRole.servingStaff,
      );

      // 🔥 FETCH ORDERS AFTER LOGIN
      if (auth.token != null) {
        await orders.fetchOrders(auth.token!);
      }

      if (mounted) {
        if (_selectedRole == StaffRole.billingStaff) {
          Navigator.of(context)
              .pushReplacementNamed('/billing');
        } else {
          Navigator.of(context)
              .pushReplacementNamed('/dashboard');
        }
      }
    } catch (e) {
      setState(() =>
          _error = 'Login failed. Please check your credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Decorative Background Elements
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.1), // gold-start/10
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .moveY(begin: 0, end: 15, duration: 3.seconds, curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05), // ruby-red/5
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .moveY(begin: 0, end: -15, duration: 4.seconds, curve: Curves.easeInOut),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 448), // max-w-md is 448px (28rem)
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16), // rounded-2xl
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 24, // shadow-xl
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2), // border-gold-start/20
                        ),
                      ),
                      padding: const EdgeInsets.all(32), // p-8
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title and Tabs
                          Text(
                            'Staff Login',
                            style: AppTheme.serif(
                              size: 30, // text-3xl
                              weight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 8),
                          Text(
                            'Access your staff dashboard',
                            style: AppTheme.sans(
                              size: 14,
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 32), // mb-8

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _error!,
                                style: AppTheme.sans(
                                  size: 14,
                                  color: AppColors.danger,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Form Fields
                          // Role Selector
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Role',
                                  style: AppTheme.sans(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RoleButton(
                                        label: 'Serving Staff',
                                        isSelected: _selectedRole ==
                                            StaffRole.servingStaff,
                                        onTap: () => setState(
                                          () => _selectedRole =
                                              StaffRole.servingStaff,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _RoleButton(
                                        label: 'Billing Staff',
                                        isSelected: _selectedRole ==
                                            StaffRole.billingStaff,
                                        onTap: () => setState(
                                          () => _selectedRole =
                                              StaffRole.billingStaff,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InputGroup(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: _staffIdController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          _InputGroup(
                            label: 'Password',
                            hint: 'Enter password',
                            controller: _staffPasswordController,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          GestureDetector(
                            onTap: auth.isLoading ? null : _handleLogin,
                            onTapDown: (_) => setState(() {}),
                            onTapUp: (_) => setState(() {}),
                            onTapCancel: () => setState(() {}),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.gold,
                                    AppColors.goldLight, // bg-linear-to-r from-gold-start to-gold-end
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: auth.isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.sans(
                                        size: 14,
                                        weight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Center(
                            child: InkWell(
                              onTap: () {},
                              child: Text(
                                'Back to Home',
                                style: AppTheme.sans(
                                  size: 14,
                                  color: AppColors.slate500,
                                ).copyWith(decoration: TextDecoration.underline),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                     .fade(duration: 500.ms)
                     .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8), // rounded-lg
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              size: 14,
              weight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.slate500,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputGroup extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;

  const _InputGroup({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.sans(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.ivory,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: AppTheme.sans(size: 14, color: AppColors.slate900),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.sans(size: 14, color: AppColors.slate400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: onToggleVisibility != null
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.slate400,
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
