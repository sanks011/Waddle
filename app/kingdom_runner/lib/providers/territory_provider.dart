import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/territory.dart';
import '../services/api_service.dart';

class TerritoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Territory> _territories = [];
  bool _isLoading = false;
  String? _error;

  List<Territory> get territories => List.unmodifiable(_territories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load territories from cache first, then fetch from API
  Future<void> loadTerritories() async {
    // Load from cache immediately for offline support
    await _loadFromCache();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _territories = await _apiService.getTerritories();
      await _saveToCache();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('Failed to load territories from API, using cached data: $e');
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_territories');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _territories = jsonList
            .map((json) => Territory.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading territories from cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(
        _territories.map((t) => t.toJson()).toList(),
      );
      await prefs.setString('cached_territories', jsonData);
    } catch (e) {
      print('Error saving territories to cache: $e');
    }
  }

  List<Territory> getTerritoriesByUser(String userId) {
    return _territories.where((t) => t.userId == userId && t.isActive).toList();
  }

  double getTotalAreaByUser(String userId) {
    return getTerritoriesByUser(
      userId,
    ).fold(0.0, (sum, territory) => sum + territory.area);
  }
}
