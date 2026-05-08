import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/menu_service.dart';

class ItemFormDialog extends StatefulWidget {
  final List<MenuCategory> categories;
  final MenuItem? item;
  final String? initialCategoryId;

  const ItemFormDialog({
    super.key,
    required this.categories,
    this.item,
    this.initialCategoryId,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late String _price;
  late String _prepTime;
  late String _imageUrl;
  final _imageController = TextEditingController();
  String _cleanedPreview = '';
  String? _selectedCategoryId;
  late bool _isAvailable;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.item?.name ?? '';
    _description = widget.item?.description ?? '';
    _price = widget.item != null ? widget.item!.price.toStringAsFixed(2) : '';
    _prepTime = widget.item?.preparationTime ?? '';
    _imageUrl = widget.item?.imageUrl ?? '';
    _imageController.text = _imageUrl;
    _cleanedPreview = _cleanImageUrl(_imageUrl);
    _isAvailable = widget.item?.isAvailable ?? true;

    if (widget.item != null) {
      _selectedCategoryId = widget.item!.categoryId;
    } else if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty) {
      _selectedCategoryId = widget.initialCategoryId;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';

    // Handle Google Search Redirects
    if (url.contains('google.com/imgres')) {
      try {
        final uri = Uri.parse(url);
        final imgUrl = uri.queryParameters['imgurl'];
        if (imgUrl != null && imgUrl.isNotEmpty) return imgUrl;
      } catch (_) {}
    }

    // Handle Bing Search Redirects
    if (url.contains('bing.com/images/search')) {
      try {
        final uri = Uri.parse(url);
        final imgUrl = uri.queryParameters['imgurl'];
        if (imgUrl != null && imgUrl.isNotEmpty) return imgUrl;
      } catch (_) {}
    }

    // Handle base64 or data urls (optional, but good to keep)
    if (url.startsWith('data:image')) return url;

    // Basic validation: if it doesn't start with http, it's likely invalid
    if (!url.startsWith('http')) return '';

    return url;
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final body = {
        'name': _name,
        'description': _description.isEmpty ? null : _description,
        'price': double.tryParse(_price) ?? 0.0,
        'image_url': _imageUrl.isEmpty ? null : _imageUrl,
        'category_id': _selectedCategoryId,
        'is_available': _isAvailable,
      };

      if (widget.item == null) {
        await MenuService.createItem(body);
      } else {
        await MenuService.updateItem(widget.item!.id, body);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text(
            'You must create a category first before adding an item.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.rubyRed,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                  onSaved: (val) => _name = val!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _price,
                  decoration: const InputDecoration(
                      labelText: 'Price (₹)', prefixText: '₹ '),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) =>
                      val == null || double.tryParse(val) == null
                          ? 'Valid price required'
                          : null,
                  onSaved: (val) => _price = val!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageController,
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    helperText:
                        '💡 Tip: Right-click any image online and select "Copy Image Address"',
                    helperStyle: TextStyle(
                        color: AppColors.rubyRed.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 11),
                    suffixIcon: _imageController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _imageController.clear();
                              setState(() => _cleanedPreview = '');
                            })
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _cleanedPreview = _cleanImageUrl(val.trim());
                    });
                  },
                  onSaved: (val) =>
                      _imageUrl = _cleanImageUrl(val?.trim() ?? ''),
                ),
                const SizedBox(height: 12),
                // --- Image Preview Section ---
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.ivoryDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _cleanedPreview.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined,
                                color: Colors.grey.shade400, size: 32),
                            const SizedBox(height: 4),
                            Text('Image Preview',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _cleanedPreview,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image,
                                    color: AppColors.danger, size: 32),
                                const SizedBox(height: 4),
                                Text('Invalid Image URL',
                                    style: TextStyle(
                                        color: AppColors.danger, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_cleanedPreview.isNotEmpty &&
                    _cleanedPreview != _imageController.text)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Direct Link Extracted Successfully!',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onSaved: (val) => _description = val?.trim() ?? '',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available',
                            style: TextStyle(fontSize: 14)),
                        activeColor: AppColors.success,
                        value: _isAvailable,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(widget.item == null ? 'Add Item' : 'Save Changes'),
        ),
      ],
    );
  }
}
