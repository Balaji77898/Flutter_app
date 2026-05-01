import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class TablesProvider extends ChangeNotifier {
  List<TableModel> _tables = [];
  bool _isLoading = false;

  List<TableModel> get tables => List.unmodifiable(_tables);
  bool get isLoading => _isLoading;

  Future<void> fetchTables(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("https://pos-backend-s380.onrender.com/api/admin/tables"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("TablesProvider: Status ${response.statusCode}");
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List tablesList = decoded['data'] ?? [];
        _tables = tablesList.map((t) => TableModel.fromJson(t)).toList();
        debugPrint("TablesProvider: Successfully loaded ${_tables.length} tables");
      } else {
        debugPrint("TablesProvider Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching tables: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
