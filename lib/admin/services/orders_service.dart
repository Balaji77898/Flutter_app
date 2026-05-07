import 'package:restaurant_unified_app/admin/services/api_service.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class OrdersService {
  static Future<List<OrderModel>> getOrders() async {
    final data =
        await ApiService.get(ApiEndpoints.ordersList, requiresAuth: true);
    final list = data as List<dynamic>;
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  static Future<OrderModel> getOrderById(String orderId) async {
    final data = await ApiService.get(ApiEndpoints.orderById(orderId),
        requiresAuth: true);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> payload) async {
    final data = await ApiService.post(ApiEndpoints.ordersList, payload,
        requiresAuth: true);
    return data as Map<String, dynamic>;
  }
}
