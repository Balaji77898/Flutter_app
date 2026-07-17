import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/orders_service.dart';
import 'package:restaurant_unified_app/admin/services/tables_service.dart';

class ManualOrderDialog extends StatefulWidget {
  final List<MenuItem> menuItems;
  final List<MenuCategory> categories;

  const ManualOrderDialog({
    super.key,
    required this.menuItems,
    required this.categories,
  });

  @override
  State<ManualOrderDialog> createState() => _ManualOrderDialogState();
}

class _ManualOrderDialogState extends State<ManualOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  List<TableModel> _tables = [];
  String? _selectedTableId;
  String _paymentMode = 'Cash';
  String _orderMode = 'Dine-in';

  bool _isLoadingTables = true;
  bool _isSubmitting = false;

  final Map<String, int> _selectedItems = {}; // menuItemId -> quantity

  // Navigation State for Menu Items
  String _viewMode = 'categories'; // 'categories' or 'items'
  MenuCategory? _activeCategory;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    try {
      final tables = await TablesService.getTables();
      setState(() {
        _tables = tables;
        _isLoadingTables = false;
      });
    } catch (e) {
      setState(() => _isLoadingTables = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load tables: $e')));
      }
    }
  }

  double get _totalAmount {
    double total = 0;
    _selectedItems.forEach((itemId, qty) {
      final item = widget.menuItems.firstWhere((i) => i.id == itemId);
      total += item.price * qty;
    });
    return total;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_orderMode == 'Dine-in' && _selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table for Dine-in')),
      );
      return;
    }
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final itemsList = _selectedItems.entries.map((e) {
        return {"menu_item_id": e.key, "quantity": e.value};
      }).toList();

      final orderTypeMap = {
        'Dine-in': 'DINE_IN',
        'Takeaway': 'TAKEAWAY',
        'Delivery': 'DELIVERY',
      };

      final payload = {
        "order_type": orderTypeMap[_orderMode] ?? 'DINE_IN',
        "table_id": _orderMode == 'Dine-in' ? _selectedTableId : null,
        "customer_name": _nameCtrl.text.trim(),
        "customer_phone": _phoneCtrl.text.trim(),
        "payment_mode": _paymentMode,
        "items": itemsList,
      };

      await OrdersService.createOrder(payload);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isDesktop ? 1000 : size.width * 0.95,
        height: size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: AppColors.rubyDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: isDesktop ? 28 : 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Create Manual Order',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: isDesktop ? 26 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: isDesktop ? _buildDesktopBody() : _buildMobileBody(),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: isDesktop ? 20 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 24 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.rubyRed,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24 : 8,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        SizedBox(width: isDesktop ? 16 : 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rubyRed,
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 40 : 8,
                                vertical: isDesktop ? 18 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Submit Order',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Details
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade100)),
            ),
            child: SingleChildScrollView(child: _buildOrderDetailsForm()),
          ),
        ),
        // Right side: Menu selection
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFF9FAFB),
            child: _buildMenuSelection(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBody() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildOrderDetailsForm(),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFF9FAFB),
            child: _buildMenuSelection(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Configuration',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.rubyDark,
            ),
          ),
          const SizedBox(height: 24),

          // Order Mode
          _fieldLabel('Order Mode'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Dine-in',
                  label:
                      FittedBox(fit: BoxFit.scaleDown, child: Text('Dine-in')),
                  icon: Icon(Icons.restaurant, size: 14),
                ),
                ButtonSegment(
                  value: 'Takeaway',
                  label:
                      FittedBox(fit: BoxFit.scaleDown, child: Text('Takeaway')),
                  icon: Icon(Icons.shopping_bag, size: 14),
                ),
                ButtonSegment(
                  value: 'Delivery',
                  label:
                      FittedBox(fit: BoxFit.scaleDown, child: Text('Delivery')),
                  icon: Icon(Icons.delivery_dining, size: 14),
                ),
              ],
              selected: {_orderMode},
              onSelectionChanged: (v) => setState(() => _orderMode = v.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.rubyRed,
                selectedForegroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Table selection (only for Dine-in)
          if (_orderMode == 'Dine-in') ...[
            _fieldLabel('Select Table'),
            _isLoadingTables
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    initialValue: _selectedTableId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    hint: const Text('Choose a table'),
                    items: _tables
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text('Table ${t.tableNumber}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTableId = v),
                    validator: (v) => _orderMode == 'Dine-in' && v == null
                        ? 'Required'
                        : null,
                  ),
            const SizedBox(height: 20),
          ],

          // Payment Mode
          _fieldLabel('Payment Mode'),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            items: [
              'Cash',
              'Card',
              'UPI',
              'Online',
            ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _paymentMode = v!),
          ),

          const SizedBox(height: 20),

          _fieldLabel('Customer Name'),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _fieldLabel('Customer Phone (Optional)'),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildMenuSelection() {
    if (_viewMode == 'categories') {
      return _buildCategoriesGrid();
    } else {
      return _buildItemsList();
    }
  }

  Widget _buildCategoriesGrid() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.category_rounded, color: AppColors.rubyRed),
              const SizedBox(width: 12),
              Text(
                'Select Category',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: widget.categories.length,
            itemBuilder: (ctx, i) {
              final cat = widget.categories[i];
              return _CategoryCard(
                category: cat,
                onTap: () {
                  setState(() {
                    _activeCategory = cat;
                    _viewMode = 'items';
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    final items = widget.menuItems
        .where((i) => i.isAvailable && i.categoryId == _activeCategory?.id)
        .toList();

    return Column(
      children: [
        // Back Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.rubyRed),
                onPressed: () => setState(() => _viewMode = 'categories'),
              ),
              const SizedBox(width: 8),
              Text(
                _activeCategory?.name ?? 'Items',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} items',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),

        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No items in this category.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final qty = _selectedItems[item.id] ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: qty > 0
                              ? AppColors.rubyRed.withValues(alpha: 0.4)
                              : AppColors.rubyDark.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (item.imageUrl != null &&
                              item.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.imageUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.price.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: AppColors.rubyRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qty > 0) ...[
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.rubyRed,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (qty == 1) {
                                        _selectedItems.remove(item.id);
                                      } else {
                                        _selectedItems[item.id] = qty - 1;
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    '$qty',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  qty > 0
                                      ? Icons.add_circle
                                      : Icons.add_circle_outline,
                                  color: AppColors.success,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedItems[item.id] = qty + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final MenuCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered
              ? (Matrix4.identity()..scaleByDouble(1.02, 1.02, 1.0, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 15 : 10,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
            border: Border.all(
              color: _isHovered
                  ? AppColors.rubyDark
                  : AppColors.rubyDark.withValues(alpha: 0.2),
              width: _isHovered ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isHovered ? AppColors.rubyRed : AppColors.rubyRed)
                      .withValues(alpha: _isHovered ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: _isHovered ? AppColors.rubyDark : AppColors.rubyRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.category.name,
                style: GoogleFonts.inter(
                  fontWeight: _isHovered ? FontWeight.w800 : FontWeight.bold,
                  fontSize: 14,
                  color: _isHovered ? AppColors.rubyDark : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
