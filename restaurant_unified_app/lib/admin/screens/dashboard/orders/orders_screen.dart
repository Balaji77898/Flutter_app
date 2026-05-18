import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
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
      final list = await OrdersService.getOrders();
      setState(() => _orders = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<OrderModel> get _filtered {
    return _orders.where((o) {
      final matchSearch = _searchQuery.isEmpty || o.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _statusFilter == 'All Status' || o.status.toUpperCase() == _statusFilter.toUpperCase();
      final matchPayment = _paymentFilter == 'All Payments' || o.paymentStatus.toUpperCase() == _paymentFilter.toUpperCase();
      final matchType = _typeFilter == 'All Types' || o.orderType.toUpperCase().replaceAll('-', '_') == _typeFilter.toUpperCase().replaceAll(' ', '_');
      
      return matchSearch && matchStatus && matchPayment && matchType;
    }).toList();
  }

  double get _totalRevenue => _orders
      .where((o) => o.paymentStatus.toUpperCase() == 'PAID')
      .fold(0, (sum, o) => sum + o.totalAmount);




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 800;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.rubyDark))
          : _error != null
              ? _buildErrorState()
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context, isMobile)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatsGrid(isMobile),
                          const SizedBox(height: 32),
                          _buildFilterSection(isMobile),
                          const SizedBox(height: 24),
                          Text('Showing ${_filtered.length} orders', 
                              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _buildOrdersList(_filtered, isMobile),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 20 : 40, isMobile ? 32 : 48, isMobile ? 20 : 40, 32),
      decoration: const BoxDecoration(
        color: AppColors.rubyDark,
        border: Border(bottom: BorderSide(color: AppColors.gold, width: 4)),
      ),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/admin/dashboard'),
                icon: const Icon(Icons.arrow_back, color: AppColors.gold),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Orders', 
                style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Track customer orders', 
                style: GoogleFonts.inter(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )
        : Row(
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
              const SizedBox(width: 48),
            ],
          ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statCard('Total Orders', _orders.length.toString(), AppColors.rubyDark, isMobile),
            const SizedBox(width: 12),
            _statCard('Placed', _orders.where((o) => o.status == 'PLACED').length.toString(), const Color(0xFF0284C7), isMobile),
            const SizedBox(width: 12),
            _statCard('Served', _orders.where((o) => o.status == 'SERVED').length.toString(), const Color(0xFF16A34A), isMobile),
            const SizedBox(width: 12),
            _statCard('Revenue', '₹${_totalRevenue.toStringAsFixed(0)}', AppColors.rubyDark, isMobile),
          ],
        ),
      );
    }

    return Row(
      children: [
        _statCard('Total Orders', _orders.length.toString(), AppColors.rubyDark, false),
        const SizedBox(width: 24),
        _statCard('Placed', _orders.where((o) => o.status == 'PLACED').length.toString(), const Color(0xFF0284C7), false),
        const SizedBox(width: 24),
        _statCard('Served', _orders.where((o) => o.status == 'SERVED').length.toString(), const Color(0xFF16A34A), false),
        const SizedBox(width: 24),
        _statCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(0)}', AppColors.rubyDark, false),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color, bool isMobile) {
    return Container(
      width: isMobile ? 130 : null,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(color: color, fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.1), width: 1),
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
          isMobile 
            ? Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search Order ID...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.rubyDark.withOpacity(0.1))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(_statusFilter, ['All Status', 'PLACED', 'CONFIRMED', 'PREPARING', 'READY', 'SERVED', 'CANCELLED'], (v) => setState(() => _statusFilter = v!)),
                  const SizedBox(height: 12),
                  _buildDropdown(_paymentFilter, ['All Payments', 'PAID', 'PENDING'], (v) => setState(() => _paymentFilter = v!)),
                  const SizedBox(height: 12),
                  _buildDropdown(_typeFilter, ['All Types', 'DINE_IN', 'TAKEAWAY'], (v) => setState(() => _typeFilter = v!)),
                ],
              )
            : Column(
                children: [
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildDropdown(_typeFilter, ['All Types', 'DINE_IN', 'TAKEAWAY'], (v) => setState(() => _typeFilter = v!))
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
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

  Widget _buildOrdersList(List<OrderModel> orders, bool isMobile) {
    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Center(child: Text('No orders found')),
      );
    }

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildOrderMobileCard(orders[i]),
      );
    }

    return _buildOrdersTable(orders);
  }

  Widget _buildOrderMobileCard(OrderModel o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${o.id.substring(0, 8)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.rubyDark)),
              _statusBadge(o.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUSTOMER', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w800)),
                    Text(o.customerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w800)),
                  Text('₹${o.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.rubyDark)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _paymentBadge(o.paymentStatus),
              ElevatedButton(
                onPressed: () => _showOrderDetails(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rubyDark.withOpacity(0.05),
                  foregroundColor: AppColors.rubyDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
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

  Widget _buildOrdersTable(List<OrderModel> orders) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rubyDark.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              children: [
                _headerCell('ORDER ID', 2),
                _headerCell('CUSTOMER', 3),
                _headerCell('TOTAL', 2),
                _headerCell('STATUS', 2),
                _headerCell('PAYMENT', 2),
                _headerCell('ACTIONS', 2),
              ],
            ),
          ),
          ...orders.asMap().entries.map((entry) => _buildOrderRow(entry.value, entry.key, orders.length)),
        ],
      ),
    );
  }

  Widget _headerCell(String label, int flex) {
    return Expanded(flex: flex, child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)));
  }

  Widget _buildOrderRow(OrderModel o, int index, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: index == total - 1 ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('#${o.id.substring(0, 8)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.rubyDark))),
          Expanded(flex: 3, child: Text(o.customerName, style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('₹${o.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: _statusBadge(o.status)),
          Expanded(flex: 2, child: _paymentBadge(o.paymentStatus)),
          Expanded(flex: 2, child: IconButton(icon: const Icon(Icons.visibility, color: AppColors.rubyDark, size: 20), onPressed: () => _showOrderDetails(o))),
        ],
      ),
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
    final dateFormat = DateFormat('MMMM dd, yyyy at hh:mm a');
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 750,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Details', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.rubyDark)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _summaryItem('Order ID', '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}', isBold: true),
                          _summaryItem('Order Type', order.orderType.replaceAll('_', ' ').toUpperCase(), isBold: true),
                          _summaryItem('Status', order.status.toUpperCase(), isBadge: true, badgeCol: const Color(0xFFFEF9C3), textCol: const Color(0xFFCA8A04)),
                          _summaryItem('Payment', order.paymentStatus.toUpperCase(), isBadge: true, badgeCol: const Color(0xFFFEF9C3), textCol: const Color(0xFFCA8A04)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.rubyDark),
                        const SizedBox(width: 8),
                        Text('Order Items', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.rubyDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Items Table
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: Colors.grey.shade50,
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(child: Center(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                Expanded(child: Center(child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                Expanded(child: Center(child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              ],
                            ),
                          ),
                          ...order.items.map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontSize: 14))),
                                Expanded(child: Center(child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 14)))),
                                Expanded(child: Center(child: Text(item.price.toStringAsFixed(2), style: const TextStyle(fontSize: 14)))),
                                Expanded(child: Center(child: Text((item.price * item.quantity).toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.rubyDark)))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Price Breakdown
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _priceRow('Subtotal', order.calculatedSubtotal.toStringAsFixed(2)),
                          const SizedBox(height: 8),
                          _priceRow('Tax', '0.00'),
                          const Divider(height: 24),
                          _priceRow('Total', (order.totalAmount > 0 ? order.totalAmount : order.calculatedSubtotal).toStringAsFixed(2), isTotal: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            Icons.payment,
                            'Payment Information',
                            [
                              'Method: ${order.paymentMethod ?? "N/A"}',
                              'Status: ${order.paymentStatus.toUpperCase()}',
                            ],
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _infoBox(
                            Icons.access_time,
                            'Timestamps',
                            [
                              'Created: ${dateFormat.format(DateTime.tryParse(order.createdAt) ?? DateTime.now())}',
                              'Updated: ${order.updatedAt != null ? dateFormat.format(DateTime.tryParse(order.updatedAt!) ?? DateTime.now()) : dateFormat.format(DateTime.tryParse(order.createdAt) ?? DateTime.now())}',
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

  Widget _summaryItem(String label, String value, {bool isBold = false, bool isBadge = false, Color? badgeCol, Color? textCol}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: badgeCol, borderRadius: BorderRadius.circular(100)),
              child: Text(value, style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else
            Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14, color: AppColors.rubyDark)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text('₹$value', style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.bold, color: isTotal ? AppColors.rubyDark : AppColors.textDark)),
      ],
    );
  }

  Widget _infoBox(IconData icon, String title, List<String> lines, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l, style: TextStyle(fontSize: 12, color: accent.withOpacity(0.8), fontWeight: FontWeight.w600)),
          )),
        ],
      ),
    );
  }
}
