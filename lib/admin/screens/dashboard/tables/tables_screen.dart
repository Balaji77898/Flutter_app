import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/tables_service.dart';

import 'package:restaurant_unified_app/staff/widgets/common_widgets.dart';
import 'package:restaurant_unified_app/utils/file_download_helper.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<TableModel> _tables = [];
  List<TableModel> _filteredTables = [];
  bool _isLoading = true;

  final _searchController = TextEditingController();
  String _statusFilter = 'All Status';
  String _tableTypeFilter = 'All Tables';

  final _tableNumCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    _loadTables();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableNumCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final list = await TablesService.getTables();
      setState(() {
        _tables = list;
        _applyFilters();
      });
    } catch (e) {
      // Error ignored
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTables = _tables.where((t) {
        final matchesSearch = t.tableNumber.toLowerCase().contains(query);
        final matchesStatus = _statusFilter == 'All Status' ||
            (_statusFilter == 'Occupied' && t.status == 'OCCUPIED') ||
            (_statusFilter == 'Empty' && t.status == 'EMPTY');
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _toggleTable(String id) async {
    try {
      await TablesService.toggleTable(id);
      _loadTables();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteTable(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Table'),
        content: const Text('Are you sure you want to delete this table?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await TablesService.deleteTable(id);
        _loadTables();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  Future<void> _downloadQR(TableModel t, String qrData) async {
    try {
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square, color: AppColors.rubyDark),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppColors.rubyDark),
      );
      final image = await painter.toImage(512);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await downloadFile(bytes, 'table_${t.tableNumber}_qr.png');
    } catch (e) {
      debugPrint('Download failed: $e');
    }
  }

  void _showQRDialog(TableModel t) {
    const baseUrl = 'https://customerfinal1.vercel.app/customer/scan-qr';
    final qrData = (t.qrCode != null && t.qrCode!.isNotEmpty)
        ? '$baseUrl?token=${t.qrCode}'
        : '$baseUrl?table=${t.id}';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2,
                      color: AppColors.rubyDark, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QR Code - Table ${t.tableNumber}',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.rubyDark)),
                        Text('Table ${t.tableNumber}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.rubyDark.withValues(alpha: 0.3),
                      width: 2),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: AppColors.rubyDark),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.rubyDark),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(8)),
                child: SelectableText(qrData,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.textMuted),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _downloadQR(t, qrData);
                      },
                      icon: const Icon(Icons.download_rounded,
                          size: 16, color: Colors.white),
                      label: const Text('Download PNG',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rubyDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: qrData));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Link copied to clipboard')),
                        );
                      },
                      icon:
                          const Icon(Icons.copy, size: 16, color: Colors.white),
                      label: const Text('Copy Link',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    _tableNumCtrl.clear();
    _capacityCtrl.text = '4';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Table',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _tableNumCtrl,
                decoration: const InputDecoration(labelText: 'Table Number')),
            const SizedBox(height: 12),
            TextField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rubyRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await TablesService.createTable({
                  'table_number': _tableNumCtrl.text,
                  'capacity': int.tryParse(_capacityCtrl.text) ?? 4,
                });
                _loadTables();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
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
      backgroundColor: const Color(0xFFF8F5F2),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.rubyRed))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        _buildFiltersBar(),
                        const SizedBox(height: 24),
                        Text('Showing ${_filteredTables.length} tables',
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 16),
                        _buildTablesList(),
                      ],
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
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            PremiumBackButton(
              onTap: () => context.go('/admin/dashboard'),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Tables Management',
                      style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Manage restaurant tables and QR codes',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, color: AppColors.rubyDark, size: 18),
              label: Text('Add Table',
                  style: GoogleFonts.inter(
                      color: AppColors.rubyDark, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _tables.length;
    final active = _tables.where((t) => t.isActive).length;
    final occupied = _tables.where((t) => t.status == 'OCCUPIED').length;
    final empty = total - occupied;

    return Row(
      children: [
        _buildStatCard('Total Tables', total.toString(), Colors.black),
        const SizedBox(width: 20),
        _buildStatCard('Active', active.toString(), Colors.green),
        const SizedBox(width: 20),
        _buildStatCard('Empty', empty.toString(), Colors.green),
        const SizedBox(width: 20),
        _buildStatCard('Occupied', occupied.toString(), Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.rubyDark.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.rubyDark.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text('Filters',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by table number...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.rubyDark.withValues(alpha: 0.2))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.rubyDark.withValues(alpha: 0.2))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.rubyDark.withValues(alpha: 0.5))),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                    _statusFilter, ['All Status', 'Occupied', 'Empty'], (v) {
                  setState(() {
                    _statusFilter = v!;
                    _applyFilters();
                  });
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdown(_tableTypeFilter, ['All Tables'], (v) {
                  setState(() => _tableTypeFilter = v!);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.rubyDark.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.inter(fontSize: 14))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTablesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.rubyDark.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              children: [
                _headerCell('TABLE NUMBER', 2),
                _headerCell('QR CODE', 2),
                _headerCell('STATUS', 2),
                _headerCell('ACTIVE', 2),
                _headerCell('ACTIONS', 2),
              ],
            ),
          ),
          // List Items
          ..._filteredTables
              .asMap()
              .entries
              .map((entry) => _buildTableRow(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _headerCell(String label, int flex) {
    return Expanded(
        flex: flex,
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted)));
  }

  Widget _buildTableRow(TableModel t, int index) {
    const baseUrl = 'https://customerfinal1.vercel.app/customer/scan-qr';
    final qrData = (t.qrCode != null && t.qrCode!.isNotEmpty)
        ? '$baseUrl?token=${t.qrCode}'
        : '$baseUrl?table=${t.id}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: index == _filteredTables.length - 1
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Table Number
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.tableNumber,
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(t.id.length > 8 ? '${t.id.substring(0, 8)}...' : t.id,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          // QR Preview
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              width: 48,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4)),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 40,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: Colors.black),
                ),
              ),
            ),
          ),
          // Status Chip
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.status == 'OCCUPIED'
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  t.status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: t.status == 'OCCUPIED'
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
            ),
          ),
          // Active Switch
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Switch(
                value: t.isActive,
                onChanged: (v) => _toggleTable(t.id),
                activeThumbColor: Colors.green,
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _actionIcon(
                    Icons.qr_code_scanner, Colors.blue, () => _showQRDialog(t)),
                const SizedBox(width: 12),
                _actionIcon(Icons.download_rounded, Colors.green,
                    () => _downloadQR(t, qrData)),
                const SizedBox(width: 12),
                _actionIcon(
                    Icons.delete_rounded, Colors.red, () => _deleteTable(t.id)),
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
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
