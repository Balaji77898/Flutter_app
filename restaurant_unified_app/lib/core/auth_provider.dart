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
    loadAuth();
  }

  Future<void> loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(kTokenKey);
    final roleStr = prefs.getString(kRoleKey);
    if (roleStr != null) {
      _role = UserRole.values.firstWhere((e) => e.name == roleStr);
    }
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
}
