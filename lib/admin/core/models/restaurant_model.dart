// ─── Restaurant Model ────────────────────────────────────────────────────────
class RestaurantProfile {
  final String id;
  final String name;
  final String restaurantType;
  final String status;
  final String? address;
  final String? city;
  final String? phone;
  final String? description;

  RestaurantProfile({
    required this.id,
    required this.name,
    required this.restaurantType,
    required this.status,
    this.address,
    this.city,
    this.phone,
    this.description,
  });

  factory RestaurantProfile.fromJson(Map<String, dynamic> json) {
    return RestaurantProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Restaurant',
      restaurantType: json['restaurant_type']?.toString() ?? 'Fine Dining',
      status: json['status']?.toString() ?? 'INACTIVE',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
      description: json['description']?.toString(),
    );
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}

// ─── Menu Category Model ──────────────────────────────────────────────────────
class MenuCategory {
  final String id;
  final String name;
  final String? description;
  final List<MenuItem> items;

  MenuCategory({
    required this.id,
    required this.name,
    this.description,
    this.items = const [],
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return MenuCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      items: rawItems.map((i) => MenuItem.fromJson(i)).toList(),
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final String? preparationTime;
  final bool isSpecial;
  final String? restaurantId;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    this.preparationTime,
    this.isSpecial = false,
    this.restaurantId,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      categoryId: (json['category_id'] ?? json['categoryId'])?.toString() ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString(),
      isAvailable: (json['is_available'] ?? json['isAvailable']) == true || (json['is_available'] ?? json['isAvailable']) == 1,
      preparationTime: (json['preparation_time'] ?? json['preparationTime'])?.toString(),
      isSpecial: (json['is_special'] ?? json['isSpecial']) == true || (json['is_special'] ?? json['isSpecial']) == 1,
      restaurantId: (json['restaurant_id'] ?? json['restaurantId'])?.toString(),
    );
  }
}

// ─── Staff Model ──────────────────────────────────────────────────────────────
class StaffMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isActive;

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.isActive,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'server',
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

// ─── Table Model ──────────────────────────────────────────────────────────────
class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final bool isActive;
  final String? qrCode;
  final String status; // 'EMPTY' or 'OCCUPIED'

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.isActive,
    this.qrCode,
    this.status = 'EMPTY',
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id']?.toString() ?? '',
      tableNumber: json['table_number']?.toString() ?? '',
      capacity: int.tryParse(json['capacity']?.toString() ?? '4') ?? 4,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      qrCode: (json['qr_token'] ?? json['qr_code'])?.toString(),
      status: json['table_status']?.toString().toUpperCase() ?? 'EMPTY',
    );
  }
}

// ─── Order Model ──────────────────────────────────────────────────────────────
class OrderModel {
  final String id;
  final String status;
  final String orderType;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final String createdAt;
  final String? updatedAt;
  final String? tableNumber;
  final String customerName;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.status,
    required this.orderType,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.tableNumber,
    this.customerName = 'Guest',
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total_amount'] ?? json['totalAmount'];
    final rawItems = json['items'] as List<dynamic>? ?? [];
    
    double parsedAmount = double.tryParse(
      (rawTotal ?? 
       json['amount'] ?? 
       json['final_amount'] ?? 
       json['bill_amount'] ?? 
       '0').toString()
    ) ?? 0;

    final items = rawItems.map((i) => OrderItem.fromJson(i)).toList();
    
    // Fallback to calculated subtotal if totalAmount is 0
    if (parsedAmount == 0 && items.isNotEmpty) {
      parsedAmount = items.fold(0, (sum, item) => sum + (item.price * item.quantity));
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PLACED',
      orderType: (json['order_type'] ?? json['orderType'])?.toString() ?? 'DINE_IN',
      totalAmount: parsedAmount,
      paymentStatus: (json['payment_status'] ?? json['paymentStatus'])?.toString() ?? 'PENDING',
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'])?.toString(),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString() ?? '',
      updatedAt: (json['updated_at'] ?? json['updatedAt'])?.toString(),
      tableNumber: (json['table_number'] ?? json['tableNumber'])?.toString(),
      customerName: (json['customer_name'] ?? json['customerName'])?.toString() ?? 'Guest',
      items: items,
    );
  }

  double get calculatedSubtotal => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Check nested menu_item or item_name
    String itemName = 'Unknown Item';
    if (json['name'] != null) {
      itemName = json['name'].toString();
    } else if (json['item_name'] != null) {
      itemName = json['item_name'].toString();
    } else if (json['menu_item'] != null && json['menu_item']['name'] != null) {
      itemName = json['menu_item']['name'].toString();
    }

    // Check nested menu_item for price
    double itemPrice = 0;
    if (json['price'] != null) {
      itemPrice = double.tryParse(json['price'].toString()) ?? 0;
    } else if (json['unit_price'] != null) {
      itemPrice = double.tryParse(json['unit_price'].toString()) ?? 0;
    } else if (json['menu_item'] != null && json['menu_item']['price'] != null) {
      itemPrice = double.tryParse(json['menu_item']['price'].toString()) ?? 0;
    } else if (json['amount'] != null) {
      itemPrice = double.tryParse(json['amount'].toString()) ?? 0;
    }

    return OrderItem(
      name: itemName,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: itemPrice,
    );
  }
}

