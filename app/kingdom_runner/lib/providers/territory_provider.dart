import 'package:flutter/foundation.dart';
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

  Future<void> loadTerritories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _territories = await _apiService.getTerritories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
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
