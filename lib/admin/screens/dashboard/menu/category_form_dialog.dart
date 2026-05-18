import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/menu_service.dart';

class CategoryFormDialog extends StatefulWidget {
  final MenuCategory? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.category?.name ?? '';
    _description = widget.category?.description ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final body = {
        'name': _name,
        'description': _description,
      };

      if (widget.category == null) {
        await MenuService.createCategory(body);
      } else {
        await MenuService.updateCategory(widget.category!.id, body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.category == null ? 'Create Category' : 'Edit Category',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.rubyRed,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
                onSaved: (val) => _description = val?.trim() ?? '',
              ),
            ],
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
              : Text(widget.category == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
