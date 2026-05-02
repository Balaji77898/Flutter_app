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
    // Always start fresh — clear any stored session so users see the login screen
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint("StaffAuthProvider loadAuth error: $e");
    }
    _token = null;
    _user = null;
    _role = null;
    notifyListeners();
  }

  // 🔥 FETCH USER PROFILE
  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$kBackendBase${ApiEndpoints.me}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      debugPrint("StaffAuthProvider: FETCH ME STATUS: ${response.statusCode}");
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;
        
        _user = StaffUser.fromJson(data);
        _role = _user!.role;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("StaffAuthProvider: Fetch profile error: $e");
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
        final data = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;
        
        // Save token and role
        _token = data['token'] ?? decoded['token'];
        _role = role;

        // Persist token
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString('auth_token', _token!);
        }

        // Fetch full profile
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
    await prefs.remove('auth_token');
    
    notifyListeners();
  }
}