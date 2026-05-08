import 'package:restaurant_unified_app/admin/services/api_service.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class RestaurantService {
  static Future<RestaurantProfile> getProfile() async {
    final data =
        await ApiService.get(ApiEndpoints.restaurant, requiresAuth: true);
    return RestaurantProfile.fromJson(data as Map<String, dynamic>);
  }

  static Future<RestaurantProfile> updateDetails(
      Map<String, dynamic> details) async {
    final data = await ApiService.put(ApiEndpoints.restaurantDetails, details,
        requiresAuth: true);
    return RestaurantProfile.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<RestaurantContact>> getContacts() async {
    final data =
        await ApiService.get(ApiEndpoints.restaurantContacts, requiresAuth: true);
    if (data is List) {
      return data
          .map((item) => RestaurantContact.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<RestaurantContact> addContact(String type, String value) async {
    final data = await ApiService.post(
        ApiEndpoints.restaurantContacts, {'type': type, 'value': value},
        requiresAuth: true);
    return RestaurantContact.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteContact(String id) async {
    await ApiService.delete(ApiEndpoints.restaurantContactById(id),
        requiresAuth: true);
  }
}
