import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/core/theme.dart';
import 'package:restaurant_unified_app/admin/core/providers/restaurant_provider.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

import 'package:restaurant_unified_app/staff/widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _typeController;
  late TextEditingController _descController;
  late TextEditingController _addrController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController();
    _descController = TextEditingController();
    _addrController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchRestaurant().then((_) {
        _populateFields();
      });
    });
  }

  void _populateFields() {
    final r = context.read<RestaurantProvider>().restaurant;
    if (r != null) {
      _typeController.text = r.restaurantType;
      _descController.text = r.description ?? '';
      _addrController.text = r.address ?? '';
      _stateController.text = r.state ?? '';
      _pincodeController.text = r.pincode ?? '';
      _phoneController.text = r.phone ?? '';
      _emailController.text = r.email ?? '';
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    _addrController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final restaurantProv = context.watch<RestaurantProvider>();
    final r = restaurantProv.restaurant;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          PageHeader(
            title: 'Restaurant Profile',
            subtitle: 'Manage your business identity',
            onBack: () => context.go('/admin/dashboard'),
          ),
          Expanded(
            child: restaurantProv.isLoading && r == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.rubyRed))
                : RefreshIndicator(
                    onRefresh: () => restaurantProv.fetchRestaurant(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Profile header card ────────────────────────────────────
                            _buildHeaderCard(r),
                            const SizedBox(height: 32),

                            // ── Restaurant Details ─────────────────────────────────────
                            Text('Restaurant Details',
                                style: AppTextStyles.title()),
                            const SizedBox(height: 16),
                            _buildDetailsGrid(r),

                            const SizedBox(height: 32),

                            // ── Contacts Section ───────────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Additional Contacts',
                                    style: AppTextStyles.title()),
                                if (_isEditing)
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _isEditing = false;
                                      _populateFields();
                                    }),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Done'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.rubyRed),
                                  )
                                else
                                  TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _isEditing = true),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Edit'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.rubyRed),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildContactsSection(restaurantProv),

                            const SizedBox(height: 32),

                            // ── Admin info ─────────────────────────────────────────────
                            Text('Admin Account', style: AppTextStyles.title()),
                            const SizedBox(height: 16),
                            _infoCard([
                              _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Account Email',
                                value: auth.userEmail ?? 'admin@restaurant.com',
                              ),
                              const _InfoRow(
                                icon: Icons.badge_outlined,
                                label: 'Role',
                                value: 'Administrator',
                              ),
                            ]),

                            const SizedBox(height: 40),

                            // ── Logout ─────────────────────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await context.read<AuthProvider>().logout();
                                  if (context.mounted) {
                                    context.go('/admin/login');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side:
                                      const BorderSide(color: AppColors.danger),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.logout, size: 18),
                                label: Text('Logout from Dashboard',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
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

  Widget _buildHeaderCard(RestaurantProfile? r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.rubyRed, AppColors.rubyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.restaurant_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r?.name ?? 'Restaurant Name',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    )),
                const SizedBox(height: 4),
                Text(r?.restaurantType ?? 'Restaurant Type',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gold.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            )),
            _buildStatusBadge(r),
          ]),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  Widget _buildStatusBadge(RestaurantProfile? r) {
    final isActive = r != null && r.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            r?.status ?? 'UNKNOWN',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isActive ? AppColors.success : AppColors.warning,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(RestaurantProfile? r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          _buildEditableRow(
            icon: Icons.category_outlined,
            label: 'Restaurant Type',
            controller: _typeController,
            hint: 'e.g. Fine Dining, Cafe',
          ),
          const Divider(height: 32, color: AppColors.slate100),
          _buildEditableRow(
            icon: Icons.description_outlined,
            label: 'Description',
            controller: _descController,
            hint: 'Brief description of your restaurant',
            maxLines: 3,
          ),
          const Divider(height: 32, color: AppColors.slate100),
          _buildEditableRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            controller: _addrController,
            hint: 'Street address',
          ),
          const Divider(height: 32, color: AppColors.slate100),
          Row(
            children: [
              Expanded(
                child: _buildEditableRow(
                  icon: Icons.map_outlined,
                  label: 'State',
                  controller: _stateController,
                  hint: 'State',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditableRow(
                  icon: Icons.pin_drop_outlined,
                  label: 'Pincode',
                  controller: _pincodeController,
                  hint: 'Pincode',
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.slate100),
          _buildEditableRow(
            icon: Icons.phone_outlined,
            label: 'Primary Phone',
            controller: _phoneController,
            hint: 'Main contact number',
          ),
          const Divider(height: 32, color: AppColors.slate100),
          _buildEditableRow(
            icon: Icons.email_outlined,
            label: 'Primary Email',
            controller: _emailController,
            hint: 'Main contact email',
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.rubyRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.rubyRed, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.overline()),
              const SizedBox(height: 4),
              Text(
                controller.text.isEmpty ? 'Not set' : controller.text,
                style: AppTextStyles.body(
                  color: controller.text.isEmpty
                      ? AppColors.slate400
                      : AppColors.slate900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactsSection(RestaurantProvider prov) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          if (prov.contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No additional contacts added.',
                  style: AppTextStyles.body(color: AppColors.slate400)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prov.contacts.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 24, color: AppColors.slate100),
              itemBuilder: (context, index) {
                final contact = prov.contacts[index];
                return Row(
                  children: [
                    Icon(
                      contact.type == 'PHONE' ? Icons.phone : Icons.email,
                      size: 18,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(contact.value,
                          style: AppTextStyles.body(color: AppColors.slate900)),
                    ),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 20),
                        onPressed: () =>
                            prov.deleteRestaurantContact(contact.id),
                      ),
                  ],
                );
              },
            ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddContactDialog(prov),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rubyRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddContactDialog(RestaurantProvider prov) {
    String type = 'PHONE';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add New Contact', style: AppTextStyles.title()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'PHONE', child: Text('Phone')),
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: type == 'PHONE' ? 'Phone Number' : 'Email Address',
                  hintText: type == 'PHONE' ? '9876543210' : 'example@mail.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  prov.addRestaurantContact(type, controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(children: [
                  Icon(row.icon, color: AppColors.slate400, size: 20),
                  const SizedBox(width: 16),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.label, style: AppTextStyles.overline()),
                        const SizedBox(height: 4),
                        Text(row.value,
                            style:
                                AppTextStyles.body(color: AppColors.slate900)),
                      ]),
                ]),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.slate100, indent: 60),
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
