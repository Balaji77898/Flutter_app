import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/theme.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/staff_service.dart';

class StaffScreen extends StatefulWidget {
  /// 'server' for Serving Staff, 'cashier' for Billing Staff
  final String role;
  const StaffScreen({super.key, required this.role});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<StaffMember> _allStaff = [];
  List<StaffMember> _filteredStaff = [];
  bool _isLoading = true;
  String? _error;

  final _searchController = TextEditingController();
  String _statusFilter = 'All Status';

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String get _roleLabel => widget.role == 'server' ? 'Serving Staff' : 'Billing Staff';
  String get _roleSubtitle => widget.role == 'server' 
      ? 'Manage floor staff and service assignments' 
      : 'Manage cashier terminals and transaction logs';

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final list = await StaffService.getStaff();
      
      setState(() {
        _allStaff = list.where((s) {
          final r = s.role.toLowerCase().trim();
          if (widget.role == 'server') {
            return r == 'serving_staff' || r == 'server' || r.contains('serv') || r == 'waiter';
          } else {
            return r == 'billing_staff' || r == 'cashier' || r.contains('bill') || r.contains('cash');
          }
        }).toList();
        _applyFilters();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = _allStaff.where((s) {
        final matchesSearch = s.name.toLowerCase().contains(query) || 
                             s.email.toLowerCase().contains(query);
        final matchesStatus = _statusFilter == 'All Status' ||
            (_statusFilter == 'Active' && s.isActive) ||
            (_statusFilter == 'Inactive' && !s.isActive);
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _toggleStaff(String id) async {
    try {
      await StaffService.toggleStaff(id);
      _loadStaff();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteStaff(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: const Text('Are you sure you want to delete this staff member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await StaffService.deleteStaff(id);
        _loadStaff();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _passCtrl.clear();
    _phoneCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $_roleLabel', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rubyRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await StaffService.createStaff({
                  'name': _nameCtrl.text,
                  'email': _emailCtrl.text,
                  'password': _passCtrl.text,
                  'phone': _phoneCtrl.text,
                  'role': widget.role == 'server' ? 'SERVING_STAFF' : 'BILLING_STAFF',
                });
                _loadStaff();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.rubyRed))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.all(40),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsRow(),
                            const SizedBox(height: 40),
                            _buildFiltersBar(),
                            const SizedBox(height: 24),
                            Text(
                              'Showing ${_filteredStaff.length} ${widget.role == 'server' ? 'serving' : 'billing'} staff members',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStaffList(),
                            const SizedBox(height: 100), // Bottom padding
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

  Widget _buildHeader() {
    return Container(
      color: AppColors.rubyDark,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/staff'),
                      icon: const Icon(Icons.arrow_back, color: AppColors.gold, size: 18),
                      label: Text('Back to Staff Management', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(_roleLabel,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white, 
                          fontSize: 48, 
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Text(_roleSubtitle,
                        style: GoogleFonts.inter(
                          color: AppColors.gold.withOpacity(0.8), 
                          fontSize: 16,
                        )),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.person_add, color: AppColors.rubyDark),
                  label: Text('Add $_roleLabel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.rubyDark,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _allStaff.length;
    final active = _allStaff.where((s) => s.isActive).length;
    final inactive = total - active;

    return Row(
      children: [
        _buildStatCard('Total $_roleLabel', total.toString(), AppColors.rubyRed),
        const SizedBox(width: 24),
        _buildStatCard('Active', active.toString(), Colors.green),
        const SizedBox(width: 24),
        _buildStatCard('Inactive', inactive.toString(), Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rubyDark.withOpacity(0.2), width: 1),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.2), width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.rubyDark.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                items: ['All Status', 'Active', 'Inactive'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  setState(() {
                    _statusFilter = v!;
                    _applyFilters();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.rubyDark.withOpacity(0.2), width: 1),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _headerCell('NAME', 2),
                    _headerCell('EMAIL', 3),
                    _headerCell('ROLE', 2),
                    _headerCell('PHONE', 2),
                    _headerCell('STATUS', 1),
                    _headerCell('ACTIONS', 1),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_filteredStaff.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text('No members found')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredStaff.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _buildStaffRow(_filteredStaff[i], i),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label, int flex) {
    return Expanded(
      flex: flex, 
      child: Text(label, 
        style: GoogleFonts.inter(
          fontSize: 11, 
          fontWeight: FontWeight.w900, 
          color: AppColors.rubyDark.withOpacity(0.4),
          letterSpacing: 1.5,
        )
      )
    );
  }

  Widget _buildStaffRow(StaffMember s, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.name, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Email
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.email, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Role
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(_roleLabel, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Phone
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(s.phone ?? '—', 
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          // Status
          Expanded(
            flex: 1,
            child: Center(
              child: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: s.isActive,
                  onChanged: (v) => _toggleStaff(s.id),
                  activeColor: AppColors.success,
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                  onPressed: () => _deleteStaff(s.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('LIVE SYSTEM', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 1)),
        ],
      ),
    );
  }
}


