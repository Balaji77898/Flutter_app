import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  Map<String, dynamic> _userToPrefsJson(UserProfile u) => {
        'id': u.id,
        'name': u.name,
        'email': u.email,
        'phone': u.phone,
        'restaurant_name': u.restaurantName,
        'created_at': u.createdAt?.toIso8601String(),
      };

  Future<void> loadAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        // Website must always require login on every visit.
        await prefs.remove(kTokenKey);
        await prefs.remove(kRoleKey);
        await prefs.remove(kUserKey);
        _token = null;
        _role = null;
        _user = null;
        notifyListeners();
        return;
      }

      // Mobile app: restore any previously saved session (like Instagram).
      final savedToken = prefs.getString(kTokenKey);
      final savedRoleName = prefs.getString(kRoleKey);
      final savedUserJson = prefs.getString(kUserKey);

      if (savedToken != null && savedRoleName != null) {
        _token = savedToken;
        _role = UserRole.values.firstWhere(
          (r) => r.name == savedRoleName,
          orElse: () => UserRole.admin,
        );
        if (savedUserJson != null) {
          try {
            _user = UserProfile.fromJson(
              json.decode(savedUserJson) as Map<String, dynamic>,
              _role!,
            );
          } catch (e) {
            debugPrint("AuthProvider: failed to restore cached user: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("AuthProvider loadAuth error: $e");
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$kBackendBase${ApiEndpoints.adminLogin}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      const role = UserRole.admin;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _role = role;

        final userData = data['user'] ??
            data['data']?['user'] ??
            data['staff'] ??
            data['data']?['staff'];
        if (userData != null) {
          _user = UserProfile.fromJson(userData, role);
        }

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString(kTokenKey, _token!);
        await prefs.setString(kRoleKey, role.name);
        if (_user != null) {
          await prefs.setString(
              kUserKey, json.encode(_userToPrefsJson(_user!)));
        }
        if (_user?.restaurantName != null &&
            _user!.restaurantName!.isNotEmpty) {
          await prefs.setString(
              'cached_restaurant_name', _user!.restaurantName!);
        }

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
    await prefs.setString(kUserKey, json.encode(_userToPrefsJson(user)));
    if (user.restaurantName != null && user.restaurantName!.isNotEmpty) {
      await prefs.setString('cached_restaurant_name', user.restaurantName!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);
    await prefs.remove(kRoleKey);
    await prefs.remove(kUserKey);
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$kBackendBase${ApiEndpoints.forgotPassword}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'redirectUrl': 'http://localhost:8080/#',
          'clientUrl': 'http://localhost:8080/#'
        }),
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
