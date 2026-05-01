import 'package:restaurant_unified_app/core/theme.dart';
import 'package:restaurant_unified_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/menu_service.dart';
import 'category_form_dialog.dart';
import 'item_form_dialog.dart';
import 'manual_order_dialog.dart';
import 'today_special_dialog.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final cats = await MenuService.getCategories();
      final items = await MenuService.getItems();
      setState(() {
        _categories = cats;
        _items = items;
        if (!cats.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = '';
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategoryId == 'SPECIALS') {
      return _items.where((i) => i.isSpecial).toList();
    }
    return _selectedCategoryId.isEmpty
        ? _items
        : _items.where((i) => i.categoryId == _selectedCategoryId).toList();
  }

  Future<void> _toggleItem(String id) async {
    try {
      await MenuService.toggleItem(id);
      setState(() {
        final idx = _items.indexWhere((i) => i.id == id);
        if (idx != -1) {
          final item = _items[idx];
          _items[idx] = MenuItem(
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price,
            isAvailable: !item.isAvailable,
            imageUrl: item.imageUrl,
            categoryId: item.categoryId,
            preparationTime: item.preparationTime,
            isSpecial: item.isSpecial,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleSpecial(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    try {
      await MenuService.updateSpecialStatus(id, !item.isSpecial);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!item.isSpecial ? 'Added to Today\'s Special' : 'Removed from Specials'),
          backgroundColor: AppColors.rubyDark,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete')
          ),
        ],
      )
    );
    
    if (confirm != true) return;
    
    try {
      await MenuService.deleteCategory(id);
      if (_selectedCategoryId == id) {
        setState(() => _selectedCategoryId = '');
      }
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
    }
  }

  void _showCategoryForm([MenuCategory? cat]) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => CategoryFormDialog(category: cat),
    );
    if (result == true) _loadData();
  }

  void _showItemForm([MenuItem? item]) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => ItemFormDialog(
        categories: _categories,
        item: item,
        initialCategoryId: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
      ),
    );
    if (result == true) _loadData();
  }

  void _showManualOrderForm() async {
    await showDialog(
      context: context,
      builder: (ctx) => ManualOrderDialog(
        menuItems: _items,
        categories: _categories,
      ),
    );
  }

  void _showTodaySpecialDialog() async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => TodaySpecialDialog(
        categories: _categories,
        allItems: _items,
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.rubyRed))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCustomHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Extra bottom padding
                  sliver: SliverToBoxAdapter(
                    child: _error != null
                        ? _buildError()
                        : isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 300, child: _buildSidebar()),
                                  const SizedBox(width: 32),
                                  Expanded(child: _buildMainContent()),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSidebar(),
                                  const SizedBox(height: 32),
                                  _buildMainContent(),
                                ],
                              ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      color: AppColors.rubyDark,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/admin/dashboard'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back, color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Text('Back to Dashboard', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Menu Management', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Manage your restaurant menu items and categories', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showManualOrderForm(),
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  label: Text('Create Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showTodaySpecialDialog(),
                  icon: const Text('⭐', style: TextStyle(fontSize: 16)),
                  label: Text("Today's Special",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showItemForm(),
                  icon: const Icon(Icons.add, color: AppColors.rubyDark),
                  label: Text('Add Menu Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.rubyDark)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, color: AppColors.rubyDark),
              const SizedBox(width: 8),
              Text('Categories', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.rubyDark)),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showCategoryForm(),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rubyDark,
              side: const BorderSide(color: AppColors.rubyDark, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          _SidebarItem(
            id: '',
            name: 'All Items',
            description: 'View all',
            isSelected: _selectedCategoryId.isEmpty,
            onTap: () => setState(() => _selectedCategoryId = ''),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              return _SidebarItem(
                id: cat.id,
                name: cat.name,
                description: cat.description ?? '',
                isSelected: _selectedCategoryId == cat.id,
                category: cat,
                onTap: () => setState(() => _selectedCategoryId = cat.id),
                onEdit: () => _showCategoryForm(cat),
                onDelete: _items.where((it) => it.categoryId == cat.id).isEmpty 
                    ? () => _deleteCategory(cat.id) 
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  // Note: _buildSidebarItem is replaced by the _SidebarItem class below

  Widget _buildMainContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Showing ${_filteredItems.length} items', style: GoogleFonts.inter(color: AppColors.textMuted)),
        ),
        const SizedBox(height: 16),
        _buildItemsGrid(),
      ],
    );
  }

  Widget _buildItemsGrid() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Text('No items found.', style: GoogleFonts.inter(color: AppColors.textMuted)),
      );
    }
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 600 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 32,
          crossAxisSpacing: 32,
          childAspectRatio: 0.75, // Much more balanced ratio
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildItemCard(items[i], i).animate().fadeIn(delay: (i * 30).ms, duration: 400.ms),
      );
    });
  }

  Widget _buildItemCard(MenuItem item, int i) {
    String categoryName = 'General';
    try {
      categoryName = _categories.firstWhere((c) => c.id == item.categoryId).name;
    } catch (_) {}

    return HoverableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.ivoryDark,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 48)),
                    )
                  : const Center(child: Icon(Icons.restaurant, color: AppColors.textMuted, size: 48)),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(item.name, 
                                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold), 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (item.isSpecial)
                              IconButton(
                                onPressed: () => _toggleSpecial(item.id),
                                icon: const Icon(
                                  Icons.star,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Today\'s Special',
                              ),
                          ],
                        ),
                      ),
                      Text('₹${item.price.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.rubyRed)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(categoryName, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        if (item.isSpecial) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.flash_on, size: 10, color: AppColors.rubyRed),
                          const SizedBox(width: 2),
                          Text('TODAY\'S SPECIAL', style: GoogleFonts.inter(fontSize: 10, color: AppColors.rubyRed, fontWeight: FontWeight.w800)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.description ?? 'No description provided.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1, // Reduced to 1 line for shorter card
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Availability', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      Switch(
                        value: item.isAvailable,
                        onChanged: (_) => _toggleItem(item.id),
                        activeColor: AppColors.success,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isAvailable ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: item.isAvailable ? AppColors.success.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3))
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: item.isAvailable ? AppColors.success : AppColors.danger),
                        const SizedBox(width: 6),
                        Text(item.isAvailable ? 'Available' : 'Unavailable', style: GoogleFonts.inter(fontSize: 10, color: item.isAvailable ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showItemForm(item),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
        const SizedBox(height: 12),
        Text(_error!, style: GoogleFonts.inter(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
      ]),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String id, name, description;
  final bool isSelected;
  final MenuCategory? category;
  final VoidCallback onTap;
  final VoidCallback? onEdit, onDelete;

  const _SidebarItem({
    required this.id,
    required this.name,
    required this.description,
    required this.isSelected,
    this.category,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isAllItems = widget.id.isEmpty;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: isAllItems 
                ? AppColors.rubyDark 
                : (widget.isSelected ? AppColors.rubyDark.withOpacity(0.05) : (_isHovered ? Colors.grey.shade50 : Colors.white)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAllItems 
                  ? Colors.transparent 
                  : (widget.isSelected ? AppColors.rubyDark.withOpacity(0.5) : (_isHovered ? AppColors.rubyDark.withOpacity(0.3) : AppColors.rubyDark.withOpacity(0.1))),
              width: 1.2,
            ),
            boxShadow: _isHovered && !isAllItems ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: isAllItems ? Colors.white : AppColors.rubyDark,
                      fontSize: 15,
                    )),
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        isAllItems ? widget.description : widget.description.toUpperCase(), 
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isAllItems ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ]
                  ],
                ),
              ),
              if (!isAllItems && widget.isSelected && widget.onEdit != null) ...[
                IconButton(
                  icon: Icon(Icons.edit, size: 16, color: AppColors.rubyDark.withOpacity(0.6)),
                  onPressed: widget.onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              if (!isAllItems && widget.onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade400),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class HoverableCard extends StatefulWidget {
  final Widget child;
  const HoverableCard({Key? key, required this.child}) : super(key: key);

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.rubyDark.withValues(alpha: 0.5), width: 1),
          boxShadow: _isHovered ? AppShadows.glow : AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
