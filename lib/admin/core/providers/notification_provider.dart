import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:restaurant_unified_app/admin/core/models/notification_model.dart';
import 'package:restaurant_unified_app/admin/services/orders_service.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  bool _isPolling = false;
  Timer? _timer;
  String? _lastCheckedOrderId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkForNewOrders();
    });
    // Initial check
    _checkForNewOrders();
  }

  void stopPolling() {
    _timer?.cancel();
    _isPolling = false;
  }

  Future<void> _checkForNewOrders() async {
    try {
      final orders = await OrdersService.getOrders();
      if (orders.isEmpty) return;

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final newestOrder = orders.first;

      if (_lastCheckedOrderId == null) {
        _lastCheckedOrderId = newestOrder.id;
        // Load the last 20 orders as initial notifications so the admin sees recent history
        // Mark them as read so they don't trigger new-order toasts
        final initialOrders = orders.take(20).toList();
        for (var order in initialOrders.reversed) {
          _addOrderNotification(order, isRead: true);
        }
        notifyListeners();
        return;
      }

      if (newestOrder.id != _lastCheckedOrderId) {
        // New orders found! Find all orders above the last seen one
        final newOrders = <OrderModel>[];
        for (var order in orders) {
          if (order.id == _lastCheckedOrderId) break;
          newOrders.add(order);
        }

        // Add them in chronological order
        for (var order in newOrders.reversed) {
          _addOrderNotification(order);
        }

        _lastCheckedOrderId = newestOrder.id;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error polling for orders: $e');
    }
  }

  void _addOrderNotification(OrderModel order, {bool isRead = false}) {
    // Robust parsing of the order's creation time
    DateTime orderTime = _parseDateTime(order.createdAt);

    final notification = NotificationModel(
      id: '${order.id}_${DateTime.now().millisecondsSinceEpoch}',
      orderId: order.id,
      customerName: order.customerName,
      message:
          'Order no ${order.id.length > 8 ? order.id.substring(0, 8) : order.id} is placed by ${order.customerName}',
      createdAt: orderTime,
    );
    notification.isRead = isRead;
    _notifications.insert(0, notification);
  }

  DateTime _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();

    // Try standard ISO
    DateTime? dt = DateTime.tryParse(dateStr);

    // Fallback: If it has a space instead of T, replace it (common in some backends)
    if (dt == null && dateStr.contains(' ')) {
      dt = DateTime.tryParse(dateStr.replaceFirst(' ', 'T'));
    }

    if (dt == null) return DateTime.now();

    // Ensure we are comparing like-with-like (Local vs Local or UTC vs UTC)
    // Most APIs return UTC. If it doesn't specify, we'll assume it might be UTC
    // and convert it to Local for the "time ago" calculation.
    return dt.isUtc ? dt.toLocal() : dt;
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
