import 'dart:convert';

class NotificationModel {
  final String id;
  final String orderId;
  final String customerName;
  final String message;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'customerName': customerName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      customerName: map['customerName'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source) => NotificationModel.fromMap(json.decode(source));
}
