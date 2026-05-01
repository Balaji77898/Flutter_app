import 'package:flutter/material.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  RestaurantProfile? _restaurant;
  bool _isLoading = false;
  String? _error;

  RestaurantProfile? get restaurant => _restaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurant() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _restaurant = await RestaurantService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _restaurant = null;
    _error = null;
    notifyListeners();
  }
}
