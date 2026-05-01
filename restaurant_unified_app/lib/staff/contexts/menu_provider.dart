import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class MenuProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<MenuItem> _items = [];
  List<MenuItem> get items => List.unmodifiable(_items);

  static const String _baseUrl = 'https://pos-backend-s380.onrender.com';


  MenuProvider();

  Future<void> fetchMenuItems({String? authToken}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      final String? token = authToken ?? 
          (await SharedPreferences.getInstance()).getString('auth_token');

      if (token == null || token.isEmpty) {
        _error = 'Not authenticated — please log in first';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      debugPrint('MenuProvider: Token length: ${token.length}');
      if (token.length > 10) {
        debugPrint('MenuProvider: Token starts with: ${token.substring(0, 10)}...');
      }

      // List of endpoints to try
      final endpoints = [
        '/api/admin/menu/items',
        '/api/menu/items',
        '/api/staff/menu/items',
        '/api/admin/menu/categories',
      ];

      bool success = false;
      String? lastError;

      for (final endpoint in endpoints) {
        final url = '$_baseUrl$endpoint';
        debugPrint('MenuProvider: Fetching from $url with headers $headers');
        
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: headers,
          ).timeout(const Duration(seconds: 10));

          debugPrint('MenuProvider: $endpoint - Status ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final bodySnippet = response.body.length > 200 
                ? '${response.body.substring(0, 200)}...' 
                : response.body;
            debugPrint('MenuProvider: Response: $bodySnippet');

            dynamic decoded = json.decode(response.body);
            List<dynamic> itemsList = _extractList(decoded);
            
            if (itemsList.isNotEmpty) {
              _items = itemsList
                  .map((j) => _parseItem(j as Map<String, dynamic>))
                  .toList();
              _items.sort((a, b) => a.category.compareTo(b.category));
              success = true;
              debugPrint('MenuProvider: Successfully parsed ${_items.length} items from $endpoint');
              break; 
            } else {
              debugPrint('MenuProvider: Endpoint $endpoint returned empty list or could not be extracted');
            }
          } else {
            lastError = 'Failed to load menu from $endpoint (${response.statusCode})';
          }
        } catch (e) {
          debugPrint('MenuProvider: Error fetching $endpoint: $e');
          lastError = 'Error: $e';
        }
      }

      if (!success) {
        _error = lastError ?? 'Failed to load menu items from any endpoint';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('MenuProvider critical error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      // Try common response shapes
      for (final key in ['data', 'items', 'menu', 'menuItems', 'menu_items', 'results']) {
        final val = decoded[key];
        if (val is List) return val;
        if (val is Map) {
          for (final inner in val.values) {
            if (inner is List) return inner;
          }
        }
      }
      for (final val in decoded.values) {
        if (val is List) return val;
      }
    }
    return [];
  }

  MenuItem _parseItem(Map<String, dynamic> json) {
    final String id =
        json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final String name =
        json['name']?.toString() ??
        json['item_name']?.toString() ??
        json['title']?.toString() ??
        'Item';
    final double price =
        double.tryParse(
          json['price']?.toString() ??
          json['selling_price']?.toString() ??
          json['rate']?.toString() ??
          '0',
        ) ?? 0.0;

    String category = 'Other';
    final rawCat = json['category'] ?? json['categoryName'] ?? json['category_name'];
    if (rawCat is String) {
      category = rawCat.isNotEmpty ? rawCat : 'Other';
    } else if (rawCat is Map) {
      category = rawCat['name']?.toString() ?? rawCat['title']?.toString() ?? 'Other';
    }

    final rawAvail =
        json['is_available'] ?? json['isAvailable'] ?? json['available'] ?? true;
    final bool isAvailable =
        rawAvail is bool ? rawAvail : rawAvail.toString() != 'false';

    return MenuItem(
      id: id,
      name: name,
      price: price,
      category: category,
      isAvailable: isAvailable,
    );
  }
}
