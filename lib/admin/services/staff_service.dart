import 'package:restaurant_unified_app/admin/services/api_service.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';

class StaffService {
  static Future<List<StaffMember>> getStaff() async {
    final data =
        await ApiService.get(ApiEndpoints.staffList, requiresAuth: true);
    final list = data as List<dynamic>;
    return list.map((e) => StaffMember.fromJson(e)).toList();
  }

  static Future<StaffMember> createStaff(Map<String, dynamic> body) async {
    final data =
        await ApiService.post(ApiEndpoints.staffList, body, requiresAuth: true);
    return StaffMember.fromJson(data);
  }

  static Future<void> toggleStaff(String staffId) async {
    await ApiService.patch(ApiEndpoints.toggleStaff(staffId),
        requiresAuth: true);
  }

  static Future<void> deleteStaff(String staffId) async {
    await ApiService.delete(ApiEndpoints.staffById(staffId),
        requiresAuth: true);
  }
}
