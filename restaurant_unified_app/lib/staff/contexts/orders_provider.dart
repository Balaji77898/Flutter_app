import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get newOrders =>
      _orders.where((o) => o.status == OrderStatus.placed).toList();

  List<Order> get activeOrders => _orders
      .where((o) =>
          o.status != OrderStatus.placed &&
          o.status != OrderStatus.cancelled)
      .toList();

  Order? findById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  // 🔥 FETCH ORDERS (WITH TOKEN)
  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
            "https://pos-backend-s380.onrender.com/api/admin/orders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

final List ordersList = decoded['data']; // 🔥 FIX

_orders = ordersList
    .map((o) => Order.fromJson(o))
    .toList();
      } else {
        debugPrint("Failed to load orders: ${response.body}");
      }
    } catch (e) {
      debugPrint("ERROR: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🔥 UPDATE STATUS (WITH TOKEN)
  Future<void> updateOrderStatus(
      String id, OrderStatus status, String token) async {
    try {
      await http.patch(
        Uri.parse(
            "https://pos-backend-s380.onrender.com/api/admin/orders/$id/status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // 🔥 IMPORTANT
        },
        body: json.encode({"status": status.name.toUpperCase()}),
      );

      // refresh after update
      await fetchOrders(token);
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // 🔥 BILL
  Future<void> generateBill(String id, String token) async {
    await updateOrderStatus(id, OrderStatus.billed, token);
  }

  Future<void> payOrder(String orderId, String token) async {
  try {
    // 🔥 STEP 1 → SERVED → BILLED
    final billedResponse = await http.patch(
      Uri.parse(
          "https://pos-backend-s380.onrender.com/api/admin/orders/$orderId/status"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "status": "BILLED",
      }),
    );

    debugPrint("BILLED STATUS: ${billedResponse.statusCode}");
    debugPrint("BILLED BODY: ${billedResponse.body}");

    // 🔥 STEP 2 → BILLED → PAID
    final paidResponse = await http.patch(
      Uri.parse(
          "https://pos-backend-s380.onrender.com/api/admin/orders/$orderId/status"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "status": "PAID",
        "payment_status": "PAID",
      }),
    );

    debugPrint("PAID STATUS: ${paidResponse.statusCode}");
    debugPrint("PAID BODY: ${paidResponse.body}");

    // 🔥 REFRESH UI
    if (paidResponse.statusCode == 200) {
      await fetchOrders(token);
    }
  } catch (e) {
    debugPrint("PAY ERROR: $e");
  }
}

  Future<void> createOrder(Map<String, dynamic> body, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("https://pos-backend-s380.onrender.com/api/admin/orders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      debugPrint("CREATE ORDER STATUS: ${response.statusCode}");
      debugPrint("CREATE ORDER BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrders(token);
      } else {
        throw Exception("Failed to create order");
      }
    } catch (e) {
      debugPrint("Create Order Error: $e");
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}