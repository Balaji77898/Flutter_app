enum StaffRole { servingStaff, billingStaff }

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  served,
  billed,
  paid,
  cancelled,
}

enum TableStatus { available, occupied }

// ---------------- STATUS EXTENSION ----------------
extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'PLACED';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.ready:
        return 'READY TO SERVE';
      case OrderStatus.served:
        return 'SERVED';
      case OrderStatus.billed:
        return 'BILLED';
      case OrderStatus.paid:
        return 'PAID';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get apiString => name.toUpperCase();
}

// ---------------- ORDER ITEM ----------------
class OrderItem {
  final String name;
  final int quantity;
  final String price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => (double.tryParse(price) ?? 0.0) * quantity;
}

// ---------------- ORDER MODEL ----------------
class Order {
  final String id;
  final String orderNumber;
  final String table;
  final String? customerName;
  final int items;
  final double total;
  final double subtotal;
  final double tax;
  final OrderStatus status;
  final String time;
  final DateTime createdAt;
  final List<String> itemsPreview;
  final List<OrderItem> itemsDetails;

  Order({
    required this.id,
    required this.orderNumber,
    required this.table,
    this.customerName,
    required this.items,
    required this.total,
    required this.subtotal,
    required this.tax,
    required this.status,
    required this.time,
    required this.createdAt,
    required this.itemsPreview,
    required this.itemsDetails,
  });

  // ✅ FINAL FIXED JSON PARSING
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];

    final tableNumber = json['table_number'] ?? json['table_id'] ?? 'N/A';

    // ✅ FIX STATUS + PAYMENT STATUS
    final statusString = json['status'] ?? '';
    final paymentStatus = json['payment_status'] ?? '';

    OrderStatus parsedStatus;

    if (paymentStatus == "PAID") {
      parsedStatus = OrderStatus.paid;
    } else {
      parsedStatus = OrderStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == statusString,
        orElse: () => OrderStatus.placed,
      );
    }

    final order = Order(
      id: json['id'] ?? '',

      orderNumber: (json['id'] ?? '')
          .toString()
          .substring(0, 6)
          .toUpperCase(),

      table: "Table $tableNumber",

      customerName: json['customer_name'],

      items: itemsList.length,

      total: double.tryParse(json['total_amount']?.toString() ?? "0") ?? 0,
      subtotal:
          double.tryParse(json['subtotal']?.toString() ?? "0") ?? 0,
      tax: double.tryParse(json['tax_amount']?.toString() ?? "0") ?? 0,

      status: parsedStatus, // ✅ IMPORTANT FIX

      time: _formatTime(json['created_at']),

      createdAt: DateTime.parse(json['created_at']),

      itemsPreview: itemsList
          .map((i) => (i['item_name'] ?? i['name']).toString())
          .toList(),

      itemsDetails: itemsList
          .map((i) => OrderItem(
                name: i['item_name'] ?? i['name'] ?? '',
                quantity: i['quantity'] ?? 0,
                price: i['price'].toString(),
              ))
          .toList(),
    );

    if (order.subtotal == 0 && order.itemsDetails.isNotEmpty) {
      double calcSubtotal = order.itemsDetails.fold(0.0, (sum, item) => sum + item.total);
      double calcTax = calcSubtotal * 0.05; // Default 5% tax
      double calcTotal = calcSubtotal + calcTax;
      
      return order.copyWith(
        subtotal: calcSubtotal,
        tax: calcTax,
        total: calcTotal,
      );
    } else if (order.tax == 0 && order.subtotal > 0) {
      // If subtotal was provided but tax is 0, calculate tax
      double calcTax = order.subtotal * 0.05;
      double calcTotal = order.subtotal + calcTax;
      return order.copyWith(
        tax: calcTax,
        total: calcTotal,
      );
    }

    return order;
  }

  // ---------------- TIME FORMAT ----------------
  static String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();

      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? table,
    String? customerName,
    int? items,
    double? total,
    double? subtotal,
    double? tax,
    OrderStatus? status,
    String? time,
    DateTime? createdAt,
    List<String>? itemsPreview,
    List<OrderItem>? itemsDetails,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      table: table ?? this.table,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      status: status ?? this.status,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      itemsPreview: itemsPreview ?? this.itemsPreview,
      itemsDetails: itemsDetails ?? this.itemsDetails,
    );
  }
}

// ---------------- TABLE MODEL ----------------
class TableModel {
  final String id;
  final String name;
  final TableStatus status;
  final int seats;
  final String? server;

  TableModel({
    required this.id,
    required this.name,
    required this.status,
    required this.seats,
    this.server,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['table_status'] ?? json['status'] ?? '').toString().toUpperCase();
    TableStatus status;
    if (statusStr == 'AVAILABLE' || statusStr == 'EMPTY' || statusStr == 'FREE') {
      status = TableStatus.available;
    } else {
      // Anything else (Occupied, Busy, Reserved, Needs Bill, etc.) is considered 'occupied'
      status = TableStatus.occupied;
    }
    return TableModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['table_number'] ?? json['tableNumber'] ?? json['name'] ?? 'Table').toString(),
      status: status,
      seats: int.tryParse(json['capacity']?.toString() ?? json['seats']?.toString() ?? '4') ?? 4,
      server: json['current_server_name'] ?? json['server'],
    );
  }
}

// ---------------- STAFF USER ----------------
class StaffUser {
  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final String? phone;
  final String? restaurantName;
  final DateTime? createdAt;

  StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.restaurantName,
    this.createdAt,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    return StaffUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] == 'SERVING_STAFF'
          ? StaffRole.servingStaff
          : StaffRole.billingStaff,
      phone: json['phone']?.toString(),
      restaurantName: json['restaurant_name']?.toString(),
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw.toString()) : null,
    );
  }
}

// ---------------- MENU ITEM ----------------
class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.isAvailable = true,
  });
}