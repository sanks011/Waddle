import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/ola_maps_config.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(email, username, password);
      _currentUser = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      _currentUser = User.fromJson(response['user']);

      // Initialize Ola Maps config with auth token
      final token = await _apiService.token;
      if (token != null) {
        await OlaMapsConfig.initialize(token);
      }

      // Save credentials for auto-login
      if (rememberMe) {
        await _storage.write(key: 'saved_email', value: email);
        await _storage.write(key: 'saved_password', value: password);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storage.delete(key: 'saved_email');
    await _storage.delete(key: 'saved_password');
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    try {
      final savedEmail = await _storage.read(key: 'saved_email');
      final savedPassword = await _storage.read(key: 'saved_password');

      if (savedEmail != null && savedPassword != null) {
        return await login(savedEmail, savedPassword, rememberMe: false);
      }
      return false;
    } catch (e) {
      print('Auto-login failed: $e');
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Failed to load current user: $e');
    }
  }

  // Onboarding data methods
  Future<bool> get isOnboardingCompleted async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<bool> saveOnboardingData({
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    double? dailyProtein,
    double? dailyCarbs,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = <String, dynamic>{
        'onboardingCompleted': true,
      };

      // Save locally + build API payload
      if (dateOfBirth != null) {
        prefs.setString('onboarding_dob', dateOfBirth.toIso8601String());
        profileData['dateOfBirth'] = dateOfBirth.toIso8601String();
      }
      if (weight != null) {
        prefs.setDouble('onboarding_weight', weight);
        profileData['weight'] = weight;
      }
      if (height != null) {
        prefs.setDouble('onboarding_height', height);
        profileData['height'] = height;
      }
      if (dailyProtein != null) {
        prefs.setDouble('onboarding_protein', dailyProtein);
        profileData['dailyProtein'] = dailyProtein;
      }
      if (dailyCarbs != null) {
        prefs.setDouble('onboarding_carbs', dailyCarbs);
        profileData['dailyCarbs'] = dailyCarbs;
      }

      // Mark as completed locally
      await prefs.setBool('onboarding_completed', true);

      // Try to send to backend (graceful failure)
      await _apiService.updateProfile(profileData);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to save onboarding data: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    // Also try to update backend
    await _apiService.updateProfile({'onboardingCompleted': true});
  }
}
