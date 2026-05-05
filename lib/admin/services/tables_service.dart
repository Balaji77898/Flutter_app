import 'package:restaurant_unified_app/admin/services/api_service.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class TablesService {
  static Future<List<TableModel>> getTables() async {
    final data =
        await ApiService.get(ApiEndpoints.tablesList, requiresAuth: true);
    final list = data as List<dynamic>;
    return list.map((e) => TableModel.fromJson(e)).toList();
  }

  static Future<TableModel> createTable(Map<String, dynamic> body) async {
    final data = await ApiService.post(ApiEndpoints.tablesList, body,
        requiresAuth: true);
    return TableModel.fromJson(data);
  }

  static Future<void> toggleTable(String tableId) async {
    await ApiService.patch(ApiEndpoints.toggleTable(tableId),
        requiresAuth: true);
  }

  static Future<void> deleteTable(String tableId) async {
    await ApiService.delete(ApiEndpoints.deleteTable(tableId),
        requiresAuth: true);
  }
}
