import 'package:restaurant_unified_app/admin/services/api_service.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class RestaurantService {
  static Future<RestaurantProfile> getProfile() async {
    final data =
        await ApiService.get(ApiEndpoints.restaurant, requiresAuth: true);
    return RestaurantProfile.fromJson(data as Map<String, dynamic>);
  }
}
