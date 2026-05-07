import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_unified_app/admin/services/api_service.dart';
import 'package:restaurant_unified_app/core/constants.dart';

class AuthService {
  /// Login — POST /api/admin/login
  /// The deployed backend returns: { success, message, data: { token, user } }
  /// ApiService._handleResponse already unwraps the envelope so [response]
  /// arrives here as { token, user }.
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await ApiService.post(
      ApiEndpoints.login,
      {'email': email, 'password': password},
      requiresAuth: false,
    );

    final data = response as Map<String, dynamic>;

    // The backend now sends { success: true, token: "...", user: { ... } } directly
    // Flutter previously expected this inside a "data" object.
    String? token;
    if (data.containsKey('token')) {
      token = data['token']?.toString();
    } else if (data.containsKey('data') && data['data'] is Map) {
      token = (data['data'] as Map)['token']?.toString();
    }

    if (token == null || token.isEmpty) {
      throw Exception('No token received from server. Response was: $data');
    }

    // Persist token for subsequent requests
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kTokenKey, token);

    // Build user object
    Map<String, dynamic> user = {'email': email};
    try {
      if (data.containsKey('user') && data['user'] is Map) {
        user = Map<String, dynamic>.from(data['user'] as Map);
      } else if (data.containsKey('data') &&
          data['data'] is Map &&
          (data['data'] as Map).containsKey('user')) {
        user = Map<String, dynamic>.from((data['data'] as Map)['user'] as Map);
      }
    } catch (_) {}

    await prefs.setString(kUserKey, email);

    return {'token': token, 'user': user};
  }

  /// Logout — clear stored credentials
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);
    await prefs.remove(kUserKey);
  }

  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kTokenKey);
  }

  /// Validate session with backend (GET /api/admin/me)
  static Future<Map<String, dynamic>?> validateSession() async {
    try {
      final data = await ApiService.get(ApiEndpoints.me, requiresAuth: true);
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
