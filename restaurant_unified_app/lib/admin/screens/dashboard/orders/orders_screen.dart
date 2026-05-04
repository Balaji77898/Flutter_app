import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/core/providers/restaurant_provider.dart';
import 'package:restaurant_unified_app/admin/services/orders_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  
  // Filters
  String _statusFilter = 'All Status';
  String _paymentFilter = 'All Payments';
  String _typeFilter = 'All Types';
  String _searchQuery = '';
  String _sortOrder = 'Newest First';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Fetch orders and restaurant profile in parallel
      await Future.wait<dynamic>([
        OrdersService.getOrders().then((list) {
          if (mounted) setState(() => _orders = list);
        }),
        context.read<RestaurantProvider>().fetchRestaurant(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderModel> get _filtered {
    final filtered = _orders.where((o) {
      final matchSearch = _searchQuery.isEmpty || o.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _statusFilter == 'All Status' || o.status.toUpperCase() == _statusFilter.toUpperCase();
      final matchPayment = _paymentFilter == 'All Payments' || o.paymentStatus.toUpperCase() == _paymentFilter.toUpperCase();
      final matchType = _typeFilter == 'All Types' || o.orderType.toUpperCase().replaceAll('-', '_') == _typeFilter.toUpperCase().replaceAll(' ', '_');
      
      return matchSearch && matchStatus && matchPayment && matchType;
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a.createdAt) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.createdAt) ?? DateTime.now();
      if (_sortOrder == 'Newest First') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return filtered;
  }

  double get _totalRevenue => _orders
      .where((o) => o.paymentStatus.toUpperCase() == 'PAID')
      .fold(0, (sum, o) => sum + o.totalAmount);

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.rubyDark))
          : _error != null
              ? _buildErrorState()
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatsGrid(),
                          const SizedBox(height: 32),
                          _buildFilterSection(),
                          const SizedBox(height: 24),
                          Text('Showing ${filtered.length} orders', 
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _buildOrdersTable(filtered),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 32),
      decoration: const BoxDecoration(
        color: AppColors.rubyDark,
        border: Border(bottom: BorderSide(color: AppColors.gold, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => context.go('/admin/dashboard'),
            icon: const Icon(Icons.arrow_back, color: AppColors.gold, size: 18),
            label: Text('Back to Dashboard', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text('Orders Management', 
                    style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('View and track customer orders', 
                    style: GoogleFonts.inter(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Placeholder to maintain spacing if needed, or just remove
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statCard('Total Orders', _orders.length.toString(), AppColors.rubyDark),
        const SizedBox(width: 24),
        _statCard('Placed', _orders.where((o) => o.status == 'PLACED').length.toString(), const Color(0xFF0284C7)),
        const SizedBox(width: 24),
        _statCard('Served', _orders.where((o) => o.status == 'SERVED').length.toString(), const Color(0xFF16A34A)),
        const SizedBox(width: 24),
        _statCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(0)}', AppColors.rubyDark),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rubyDark.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 20, color: AppColors.rubyDark),
              const SizedBox(width: 8),
              Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.rubyDark)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.rubyDark.withOpacity(0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.rubyDark.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.rubyDark.withOpacity(0.5))),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown(_statusFilter, ['All Status', 'PLACED', 'CONFIRMED', 'PREPARING', 'READY', 'SERVED', 'CANCELLED'], (v) => setState(() => _statusFilter = v!))),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown(_paymentFilter, ['All Payments', 'PAID', 'PENDING'], (v) => setState(() => _paymentFilter = v!))),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.rubyDark.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('dd-mm-yyyy', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildDropdown(_typeFilter, ['All Types', 'DINE_IN', 'TAKEAWAY'], (v) => setState(() => _typeFilter = v!))
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildDropdown(_sortOrder, ['Newest First', 'Oldest First'], (v) => setState(() => _sortOrder = v!))
              ),
              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrdersTable(List<OrderModel> orders) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
            child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white),
          dataRowMaxHeight: 80,
          horizontalMargin: 24,
          columnSpacing: 24,
          dividerThickness: 1,
          columns: [
            DataColumn(label: Text('ORDER ID', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('CUSTOMER', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('TABLE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('STATUS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('TOTAL AMOUNT', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('PAYMENT', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('DATE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
            DataColumn(label: Text('ACTIONS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5))),
          ],
          rows: orders.map((o) => DataRow(cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${o.id.substring(0, 8)}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.rubyDark, fontSize: 13)),
                  const SizedBox(height: 6),
                  _badge(o.orderType.replaceAll('_', '-'), const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                ],
              )
            ),
            DataCell(
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(o.customerName, 
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            ),
            DataCell(
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(o.tableNumber ?? 'N/A', 
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            ),
            DataCell(_statusBadge(o.status)),
            DataCell(Text('₹${o.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.rubyDark, fontSize: 14))),
            DataCell(_paymentBadge(o.paymentStatus)),
            DataCell(Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(o.createdAt) ?? DateTime.now()), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
            DataCell(ElevatedButton.icon(
              onPressed: () => _showOrderDetails(o),
              icon: const Icon(Icons.visibility, size: 14),
              label: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            )),
          ])).toList(),
        ),
      ),
    ),
  ),
);
}

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: GoogleFonts.inter(color: textCol, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFE0F2FE);
    Color text = const Color(0xFF0284C7);
    
    if (status.toUpperCase() == 'SERVED') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF16A34A);
    } else if (status.toUpperCase() == 'CANCELLED') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
    } else if (status.toUpperCase() == 'PREPARING') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100), border: Border.all(color: text.withOpacity(0.3))),
      child: Text(status.toUpperCase() == 'PLACED' ? 'Placed' : status, style: GoogleFonts.inter(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _paymentBadge(String status) {
    Color bg = const Color(0xFFFEF9C3);
    Color text = const Color(0xFFCA8A04);
    
    if (status.toUpperCase() == 'PAID') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF16A34A);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100), border: Border.all(color: text.withOpacity(0.3))),
      child: Text(status.toUpperCase() == 'PENDING' ? 'Pending' : status, style: GoogleFonts.inter(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderDetailsDialog(order: order),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.inter(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailsDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("MMMM dd, yyyy 'at' hh:mm a");
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 850,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Details', 
                    style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.rubyDark)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Summary Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _summaryItem('Order ID', '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}', isBold: true),
                          _summaryItem('Order Type', order.orderType.replaceAll('_', ' ').toUpperCase(), isBold: true),
                          _summaryItem('Status', order.status.toUpperCase(), 
                            isBadge: true, 
                            badgeCol: const Color(0xFFD1FAE5), 
                            textCol: const Color(0xFF059669)),
                          _summaryItem('Payment', order.paymentStatus.toUpperCase(), 
                            isBadge: true, 
                            badgeCol: const Color(0xFFD1FAE5), 
                            textCol: const Color(0xFF059669)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Finalized Order Actions
                    Text('FINALIZED ORDER', 
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600, letterSpacing: 1.0)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _actionButton(context, 'Print Receipt', Icons.print, const Color(0xFF1E293B), () {
                            final restaurantName = context.read<RestaurantProvider>().restaurant?.name ?? 'RESTAURANT';
                            _handlePrint(context, restaurantName);
                          }),
                          const SizedBox(width: 16),
                          _actionButton(context, 'Download Receipt', Icons.file_download, const Color(0xFF0284C7), () {
                            final restaurantName = context.read<RestaurantProvider>().restaurant?.name ?? 'RESTAURANT';
                            _handleDownload(context, restaurantName);
                          }),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Receipt Header
                    Center(
                      child: Column(
                        children: [
                          Consumer<RestaurantProvider>(
                            builder: (context, provider, child) {
                              return Text((provider.restaurant?.name ?? 'RESTAURANT').toUpperCase(), 
                                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 2.0));
                            }
                          ),
                          const SizedBox(height: 8),
                          Text('PAYMENT RECEIPT', 
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 24),
                    
                    // Bill Details
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _billDetailRow('Bill Number', 'BILL-${order.id.toUpperCase()}'),
                          _billDetailRow('Date', dateFormat.format(DateTime.tryParse(order.createdAt) ?? DateTime.now())),
                          _billDetailRow('Payment Method', order.paymentMethod ?? 'Cash'),
                          _billDetailRow('Table', 'Table ${order.tableNumber ?? 't1'}'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Text('ORDER ITEMS', 
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900, letterSpacing: 1.0)),
                    const SizedBox(height: 16),
                    
                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: _tableHeader('Item')),
                                Expanded(child: Center(child: _tableHeader('Qty'))),
                                Expanded(child: Center(child: _tableHeader('Price'))),
                                Expanded(child: Center(child: _tableHeader('Total'))),
                              ],
                            ),
                          ),
                          ...order.items.map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(item.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate900))),
                                Expanded(child: Center(child: Text(item.quantity.toString(), style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate700)))),
                                Expanded(child: Center(child: Text('₹${item.price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate700)))),
                                Expanded(child: Center(child: Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', 
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900)))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Totals
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _priceRow('Subtotal', order.calculatedSubtotal.toStringAsFixed(0)),
                          const SizedBox(height: 12),
                          _priceRow('Tax (5%)', (order.calculatedSubtotal * 0.05).toStringAsFixed(0)),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFCBD5E1)),
                          ),
                          _priceRow('TOTAL', (order.calculatedSubtotal * 1.05).toStringAsFixed(0), isTotal: true),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Bottom Info
                    Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            Icons.credit_card,
                            'Payment Information',
                            [
                              'Method: ${order.paymentMethod ?? "N/A"}',
                              'Status: ${order.paymentStatus.toUpperCase()}',
                            ],
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _infoBox(
                            Icons.schedule,
                            'Timestamps',
                            [
                              'Created: ${dateFormat.format(DateTime.tryParse(order.createdAt) ?? DateTime.now())}',
                              'Updated: ${order.updatedAt != null ? dateFormat.format(DateTime.tryParse(order.updatedAt!) ?? DateTime.now()) : "N/A"}',
                            ],
                            const Color(0xFFFAF5FF),
                            const Color(0xFF6B21A8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700, letterSpacing: 0.5));
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context, String restaurantName) async {
    final pdf = await _generateReceiptPdf(restaurantName);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${order.id}',
    );
  }

  Future<void> _handleDownload(BuildContext context, String restaurantName) async {
    final pdf = await _generateReceiptPdf(restaurantName);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Receipt_${order.id}.pdf',
    );
  }

  Future<pw.Document> _generateReceiptPdf(String restaurantName) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat("MMMM dd, yyyy 'at' hh:mm a");
    final dateStr = dateFormat.format(DateTime.tryParse(order.createdAt) ?? DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Payment Receipt',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(height: 2, color: PdfColors.black),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Bill info
              _pdfRow('Bill Number', 'BILL-${order.id.toUpperCase()}'),
              _pdfRow('Date', dateStr),
              _pdfRow('Payment Method', order.paymentMethod ?? 'Cash'),
              _pdfRow('Table', 'Table ${order.tableNumber ?? 't1'}'),

              pw.SizedBox(height: 24),
              pw.Text('Order Items', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...order.items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.quantity.toString(), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${item.price.toStringAsFixed(0)}', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  )),
                ],
              ),

              pw.SizedBox(height: 24),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _pdfPriceRow('Subtotal', order.calculatedSubtotal.toStringAsFixed(0)),
                      _pdfPriceRow('Tax (5%)', (order.calculatedSubtotal * 0.05).toStringAsFixed(0)),
                      pw.Divider(color: PdfColors.grey400),
                      _pdfPriceRow('TOTAL', (order.calculatedSubtotal * 1.05).toStringAsFixed(0), isTotal: true),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Center(
                child: pw.Text('Thank you for dining with us!', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _pdfPriceRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: isTotal ? 14 : 12, fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('₹$value', style: pw.TextStyle(fontSize: isTotal ? 14 : 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _billDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate500, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {bool isBold = false, bool isBadge = false, Color? badgeCol, Color? textCol}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: badgeCol, borderRadius: BorderRadius.circular(100)),
              child: Text(value, style: GoogleFonts.inter(color: textCol, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            Text(value, style: GoogleFonts.inter(fontWeight: isBold ? FontWeight.w900 : FontWeight.w500, fontSize: 16, color: AppColors.slate900)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: isTotal ? 18 : 14, 
          fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
          color: isTotal ? AppColors.slate900 : AppColors.slate600,
        )),
        Text('₹$value', style: GoogleFonts.inter(
          fontSize: isTotal ? 20 : 16, 
          fontWeight: FontWeight.w900, 
          color: AppColors.slate900,
        )),
      ],
    );
  }

  Widget _infoBox(IconData icon, String title, List<String> lines, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          const SizedBox(height: 16),
          ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(l, style: GoogleFonts.inter(fontSize: 13, color: accent.withOpacity(0.8), fontWeight: FontWeight.w600)),
          )),
        ],
      ),
    );
  }
}
