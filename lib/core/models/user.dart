import '../constants.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? restaurantName;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.restaurantName,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, UserRole role) {
    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    return UserProfile(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: role,
      phone: json['phone']?.toString(),
      restaurantName:
          json['restaurant_name']?.toString() ?? json['restaurant']?.toString(),
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw.toString())
          : null,
    );
  }
}
