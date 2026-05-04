import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'models/user.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  UserProfile? _user;
  UserRole? _role;
  bool _isLoading = false;

  String? get token => _token;
  UserProfile? get user => _user;
  UserRole? get role => _role;
  String? get userEmail => _user?.email;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    // Initialization handled in main.dart
  }

  Future<void> loadAuth() async {
    // Always start fresh — clear any stored session so users see the login screen
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kTokenKey);
      await prefs.remove(kRoleKey);
    } catch (e) {
      debugPrint("AuthProvider loadAuth error: $e");
    }
    _token = null;
    _role = null;
    _user = null;
    notifyListeners();
  }

  Future<void> login(String email, String password, UserRole role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = role == UserRole.admin 
          ? ApiEndpoints.adminLogin 
          : ApiEndpoints.staffLogin;

      final response = await http.post(
        Uri.parse('$kBackendBase$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _role = role;

        final userData = data['user'] ?? data['data']?['user'] ?? data['staff'] ?? data['data']?['staff'];
        if (userData != null) {
          _user = UserProfile.fromJson(userData, role);
        }

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString(kTokenKey, _token!);
        await prefs.setString(kRoleKey, role.name);
        
        notifyListeners();
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAuth(String token, UserProfile user) async {
    _token = token;
    _user = user;
    _role = user.role;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kTokenKey, _token!);
    await prefs.setString(kRoleKey, _role!.name);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);
    await prefs.remove(kRoleKey);
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$kBackendBase${ApiEndpoints.forgotPassword}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send reset email: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String token, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$kBackendBase${ApiEndpoints.resetPassword}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
