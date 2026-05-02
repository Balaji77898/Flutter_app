import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
    loadAuth();
  }

  Future<void> loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      await fetchUserProfile();
    }
  }

  // 🔥 FETCH USER PROFILE
  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse("https://pos-backend-s380.onrender.com/api/staff/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      debugPrint("FETCH ME STATUS: ${response.statusCode}");
      debugPrint("FETCH ME BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'] ?? data['staff'];
        if (data['success'] == true && userData != null) {
          _user = StaffUser.fromJson(userData);
          _role = _role ?? _user!.role;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Fetch profile error: $e");
    }
  }

  // 🔥 LOGIN WITH API
  Future<void> login(String email, String password, StaffRole role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("https://pos-backend-s380.onrender.com/api/staff/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("LOGIN STATUS: ${response.statusCode}");
      debugPrint("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("LOGIN DATA KEYS: ${data.keys.toList()}");

        // 🔥 SAVE TOKEN AND SELECTED ROLE
        _token = data['token'];
        _role = role;

        // 🔥 PERSIST TOKEN
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString('auth_token', _token!);
        }

        // 🔥 FETCH FULL PROFILE
        await fetchUserProfile();
      } else {
        throw Exception("Login failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Login error: $e");
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