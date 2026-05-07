import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../../core/constants.dart';

class StaffAuthProvider extends ChangeNotifier {
  StaffUser? _user;
  StaffRole? _role;
  bool _isLoading = false;

  String? _token;

  // ✅ GETTERS
  StaffUser? get user => _user;
  StaffRole? get role => _role;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get token => _token;

  StaffAuthProvider() {
    // Initialization handled in main.dart
  }

  Future<void> loadAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(kTokenKey);
      if (_token != null) {
        await fetchUserProfile();
      }
    } catch (e) {
      debugPrint("StaffAuthProvider loadAuth error: $e");
    }
    notifyListeners();
  }

  // 🔥 FETCH USER PROFILE
  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    final endpoints = [
      ApiEndpoints.me, // /api/admin/me
      '/api/staff/me',
      '/api/staff/profile',
      '/api/auth/me',
    ];

    for (final endpoint in endpoints) {
      try {
        debugPrint("StaffAuthProvider: Trying profile endpoint: $endpoint");
        final response = await http.get(
          Uri.parse("$kBackendBase$endpoint"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token",
          },
        );

        debugPrint(
            "StaffAuthProvider: FETCH PROFILE ($endpoint) STATUS: ${response.statusCode}");
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          final data = (decoded is Map && decoded.containsKey('data'))
              ? decoded['data']
              : (decoded is Map && decoded.containsKey('user'))
                  ? decoded['user']
                  : decoded;

          if (data is Map<String, dynamic>) {
            _user = StaffUser.fromJson(data);
            _role = _user!.role;
            notifyListeners();
            return; // Success!
          }
        }
      } catch (e) {
        debugPrint("StaffAuthProvider: Error with endpoint $endpoint: $e");
      }
    }
  }

  // 🔥 LOGIN WITH API
  Future<void> login(String email, String password, StaffRole role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("$kBackendBase${ApiEndpoints.staffLogin}"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("StaffAuthProvider: LOGIN STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : decoded;

        // Save token and role
        _token = data['token'] ?? decoded['token'];
        _role = role;

        // Try to get user from login response first
        final userData = data['user'] ?? decoded['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          _user = StaffUser.fromJson(userData);
          _role = _user!.role;
        }

        // Persist token
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString(kTokenKey, _token!);
        }

        // Fetch/Refresh full profile
        await fetchUserProfile();
      } else {
        throw Exception("Login failed (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("StaffAuthProvider: Login error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 LOGOUT
  Future<void> logout() async {
    _user = null;
    _role = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);

    notifyListeners();
  }
}
