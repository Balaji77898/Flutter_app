import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_unified_app/core/constants.dart';

/// Central HTTP client — all API calls go through this.
/// Mirrors the Next.js api.service.ts + proxy.ts behaviour.
class ApiService {
  static Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(kTokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('$kBackendBase$path');

  /// GET request
  static Future<dynamic> get(String path, {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    debugPrint('API GET: $path');
    final response = await http
        .get(_uri(path), headers: headers)
        .timeout(const Duration(seconds: 40));
    return _handleResponse(response, path);
  }

  /// POST request
  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    debugPrint('API POST: $path | Body: ${jsonEncode(body)}');
    final response = await http
        .post(_uri(path), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 40));
    return _handleResponse(response, path);
  }

  /// PUT request
  static Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    debugPrint('API PUT: $path | Body: ${jsonEncode(body)}');
    final response = await http
        .put(_uri(path), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 40));
    return _handleResponse(response, path);
  }

  /// PATCH request (Refreshed)
  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    debugPrint(
      'API PATCH: $path | Body: ${body != null ? jsonEncode(body) : "EMPTY"}',
    );
    final response = await http
        .patch(
          _uri(path),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 40));
    return _handleResponse(response, path);
  }

  /// DELETE request
  static Future<dynamic> delete(String path, {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    debugPrint('API DELETE: $path');
    final response = await http
        .delete(_uri(path), headers: headers)
        .timeout(const Duration(seconds: 40));
    return _handleResponse(response, path);
  }

  static dynamic _handleResponse(http.Response response, String path) {
    final body = response.body;
    debugPrint('API RESPONSE [$path] (${response.statusCode}): $body');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return {};
      final decoded = jsonDecode(body);
      // Unwrap the { success, message, data } envelope used by the deployed backend.
      // If the response IS the envelope (has a 'data' key), return data.
      // Otherwise fall back to returning the raw decoded value (list or map).
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('success') && decoded['success'] == false) {
          throw Exception(
            decoded['message'] ?? decoded['error'] ?? 'Request failed',
          );
        }
        if (decoded.containsKey('data')) {
          return decoded['data'];
        }
      }
      return decoded;
    } else {
      String message = 'Request failed (${response.statusCode})';
      try {
        final json = jsonDecode(body);
        message = json['message'] ?? json['error'] ?? message;
      } catch (_) {}
      if (response.statusCode == 401) {
        throw Exception('Invalid email or password. Please try again.');
      }
      if (response.statusCode == 403) {
        throw Exception(
          'Access denied. Your account may not have admin privileges.',
        );
      }
      throw Exception(message);
    }
  }
}
