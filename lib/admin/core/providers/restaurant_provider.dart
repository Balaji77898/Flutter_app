import 'package:flutter/material.dart';
import 'package:restaurant_unified_app/admin/core/models/restaurant_model.dart';
import 'package:restaurant_unified_app/admin/services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  RestaurantProfile? _restaurant;
  List<RestaurantContact> _contacts = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  RestaurantProfile? get restaurant => _restaurant;
  List<RestaurantContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> fetchRestaurant() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _restaurant = await RestaurantService.getProfile();
      _contacts = await RestaurantService.getContacts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRestaurantDetails(Map<String, dynamic> details) async {
    try {
      _isLoading = true;
      _error = null;
      _successMessage = null;
      notifyListeners();

      _restaurant = await RestaurantService.updateDetails(details);
      _successMessage = "Restaurant details updated";
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchContacts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _contacts = await RestaurantService.getContacts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRestaurantContact(String type, String value) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await RestaurantService.addContact(type, value);
      _contacts = await RestaurantService.getContacts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRestaurantContact(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await RestaurantService.deleteContact(id);
      _contacts = await RestaurantService.getContacts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  void clear() {
    _restaurant = null;
    _contacts = [];
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
