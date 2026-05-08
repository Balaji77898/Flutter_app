import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/staff/contexts/menu_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_unified_app/staff/contexts/orders_provider.dart';
import 'package:restaurant_unified_app/staff/models/models.dart';

class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  String? _tableNumber;
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadTableInfo();
    // Fetch menu - assuming public access or a shared token logic exists
    // For now, we try to fetch using any existing token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().fetchMenuItems();
    });
  }

  Future<void> _loadTableInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tableNumber = prefs.getString('tableNumber');
    });
  }

  double get _totalAmount {
    final menuItems = context.read<MenuProvider>().items;
    double total = 0;
    _cart.forEach((id, qty) {
      final item = menuItems.firstWhere((m) => m.id == id);
      total += item.price * qty;
    });
    return total;
  }

  bool _isPlacingOrder = false;

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final menuItems = context.read<MenuProvider>().items;
      final List<Map<String, dynamic>> itemsData = [];

      _cart.forEach((id, qty) {
        final item = menuItems.firstWhere((m) => m.id == id);
        itemsData.add({
          "menu_item_id": id,
          "name": item.name,
          "quantity": qty,
          "price": item.price,
        });
      });

      final orderData = {
        "items": itemsData,
        "tableNumber": _tableNumber ?? "Unknown",
        "order_type": "DINE_IN",
        "total_amount": _totalAmount,
      };

      await context.read<OrdersProvider>().placeCustomerOrder(orderData);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Placed!'),
            content: Text(
                'Your order for Table #$_tableNumber has been sent to the kitchen.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _cart.clear());
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to place order: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.rubyDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/customer/scan-qr'),
        ),
        title: Text('Restaurant Menu',
            style: GoogleFonts.playfairDisplay(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (_tableNumber != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Table #$_tableNumber',
                    style: GoogleFonts.inter(
                        color: AppColors.rubyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: menu.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.rubyRed))
          : menu.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(menu.error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => menu.fetchMenuItems(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: menu.items.length,
                        itemBuilder: (context, index) {
                          final item = menu.items[index];
                          final qty = _cart[item.id] ?? 0;
                          return _buildItemCard(item, qty);
                        },
                      ),
                    ),
                    if (_cart.isNotEmpty) _buildBottomBar(),
                  ],
                ),
    );
  }

  Widget _buildItemCard(MenuItem item, int qty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(item.category,
                      style:
                          GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('₹${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                          color: AppColors.rubyRed,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Row(
              children: [
                if (qty > 0) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.rubyRed),
                    onPressed: () => setState(() {
                      if (qty == 1)
                        _cart.remove(item.id);
                      else
                        _cart[item.id] = qty - 1;
                    }),
                  ),
                  Text('$qty',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ],
                IconButton(
                  icon: Icon(
                      qty > 0 ? Icons.add_circle : Icons.add_circle_outline,
                      color: Colors.green),
                  onPressed: () => setState(() => _cart[item.id] = qty + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Amount',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                Text('₹${_totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.rubyRed)),
              ],
            ),
            ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rubyDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Order',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
