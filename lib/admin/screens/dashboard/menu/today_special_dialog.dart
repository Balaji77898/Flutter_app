import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/menu_service.dart';

/// Dialog that lets the admin pick any existing menu items and
/// reassign them to the "Today's Special" category (creating that
/// category on-the-fly if it doesn't exist yet).
class TodaySpecialDialog extends StatefulWidget {
  final List<MenuCategory> categories;
  final List<MenuItem> allItems;

  const TodaySpecialDialog({
    super.key,
    required this.categories,
    required this.allItems,
  });

  @override
  State<TodaySpecialDialog> createState() => _TodaySpecialDialogState();
}

class _TodaySpecialDialogState extends State<TodaySpecialDialog> {
  late Set<String> _specialItemIds;
  bool _isSubmitting = false;
  String _searchQuery = '';

  // The ID of the "Today's Special" category (null if not yet created)
  String? _specialCategoryId;

  @override
  void initState() {
    super.initState();
    // Find the category
    final specialCat = widget.categories.firstWhere(
      (c) =>
          c.name.toLowerCase().contains('today') ||
          c.name.toLowerCase().contains('special'),
      orElse: () => MenuCategory(id: '', name: ''),
    );
    _specialCategoryId = specialCat.id.isEmpty ? null : specialCat.id;

    // Pre-select items already in Today's Special
    _specialItemIds = widget.allItems
        .where((i) => i.categoryId == _specialCategoryId)
        .map((i) => i.id)
        .toSet();
  }

  List<MenuItem> get _filteredItems {
    final q = _searchQuery.toLowerCase();
    return widget.allItems
        .where((i) => q.isEmpty || i.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);
    try {
      String catId = _specialCategoryId ?? '';

      // Create the category if it doesn't exist yet
      if (catId.isEmpty) {
        final newCat = await MenuService.createCategory({
          'name': "Today's Special",
          'description': 'Daily specials curated by the chef',
        });
        catId = newCat.id;
      }

      // For each item, update its categoryId if it changed
      final futures = <Future>[];
      for (final item in widget.allItems) {
        final shouldBeSpecial = _specialItemIds.contains(item.id);
        final isCurrentlySpecial = item.categoryId == _specialCategoryId;

        if (shouldBeSpecial && !isCurrentlySpecial) {
          // Move to Today's Special
          futures.add(
            MenuService.updateItem(item.id, {
              'name': item.name,
              'description': item.description ?? '',
              'price': item.price,
              'is_available': item.isAvailable,
              'image_url': item.imageUrl ?? '',
              'category_id': catId,
              'preparation_time': item.preparationTime ?? '',
            }),
          );
        } else if (!shouldBeSpecial && isCurrentlySpecial) {
          // Remove from Today's Special — move to first non-special category
          final fallback = widget.categories
                  .where((c) => c.id != _specialCategoryId && c.id.isNotEmpty)
                  .map((c) => c.id)
                  .firstOrNull ??
              '';
          if (fallback.isNotEmpty) {
            futures.add(
              MenuService.updateItem(item.id, {
                'name': item.name,
                'description': item.description ?? '',
                'price': item.price,
                'is_available': item.isAvailable,
                'image_url': item.imageUrl ?? '',
                'category_id': fallback,
                'preparation_time': item.preparationTime ?? '',
              }),
            );
          }
        }
      }

      await Future.wait(futures);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Today's Special updated!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
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
    final filtered = _filteredItems;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: size.width < 600 ? size.width * 0.95 : 520,
        height: size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.rubyDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    "Today's Special",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Subtitle ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              color: AppColors.gold.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Select items to feature as Today\'s Special. Unselected items are removed.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),

            // ── Item List ───────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final isSelected = _specialItemIds.contains(item.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _specialItemIds.add(item.id);
                              } else {
                                _specialItemIds.remove(item.id);
                              }
                            });
                          },
                          activeColor: AppColors.rubyDark,
                          title: Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.rubyDark
                                  : AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          secondary:
                              item.imageUrl != null && item.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        item.imageUrl!,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.ivoryDark,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.fastfood,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: isSelected
                              ? AppColors.rubyDark.withValues(alpha: 0.05)
                              : null,
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                children: [
                  Text(
                    '${_specialItemIds.length} item${_specialItemIds.length == 1 ? '' : 's'} selected',
                    style: GoogleFonts.inter(
                      color: AppColors.rubyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _save,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('⭐', style: TextStyle(fontSize: 14)),
                        label: Text(
                          'Save Specials',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rubyDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
