import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:restaurant_unified_app/admin/core/models/notification_model.dart';
import 'package:restaurant_unified_app/admin/services/orders_service.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isPolling = false;
  Timer? _timer;
  String? _lastCheckedOrderId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
        // Don't return here, if we want to notify about the latest one immediately on first load
        _addOrderNotification(newestOrder);
        notifyListeners();
        return;
      }

      if (newestOrder.id != _lastCheckedOrderId) {
        // New orders found!
        final newOrders = orders.where((o) => _isOrderNewerThanLast(o, _lastCheckedOrderId!)).toList();
        
        for (var order in newOrders.reversed) { // Add in chronological order
          _addOrderNotification(order);
        }
        
        _lastCheckedOrderId = newestOrder.id;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error polling for orders: $e');
    }
  }

  bool _isOrderNewerThanLast(OrderModel order, String lastId) {
    // This is a simple check. In a real app, we might compare timestamps.
    // For now, if the ID is different and it's in the top of the list, we treat it as new.
    return order.id != lastId;
  }

  void _addOrderNotification(OrderModel order) {
    // Parse the order's creation time, fallback to now if parsing fails
    DateTime orderTime = DateTime.tryParse(order.createdAt) ?? DateTime.now();
    
    // If the parsed time is in UTC, convert it to local for correct difference calculation
    if (orderTime.isUtc) {
      orderTime = orderTime.toLocal();
    }

    final notification = NotificationModel(
      id: '${order.id}_${DateTime.now().millisecondsSinceEpoch}',
      orderId: order.id,
      customerName: order.customerName,
      message: 'Order no ${order.id.substring(0, 8)} is placed by ${order.customerName}',
      createdAt: orderTime,
    );
    _notifications.insert(0, notification);
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
