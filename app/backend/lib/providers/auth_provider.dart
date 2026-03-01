import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

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
  ApiService get apiService => _apiService;

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
      // Primary: use stored JWT token — no network re-login needed
      final token = await _apiService.token;
      if (token != null && token.isNotEmpty) {
        try {
          _currentUser = await _apiService.getCurrentUser();
          // Merge locally-saved avatar
          if (_currentUser != null) {
            final prefs = await SharedPreferences.getInstance();
            final savedAvatar = prefs.getString('onboarding_avatar');
            if (_currentUser!.avatarPath == null && savedAvatar != null) {
              _currentUser = User(
                id: _currentUser!.id,
                email: _currentUser!.email,
                username: _currentUser!.username,
                totalDistance: _currentUser!.totalDistance,
                territorySize: _currentUser!.territorySize,
                activityStreak: _currentUser!.activityStreak,
                lastActivity: _currentUser!.lastActivity,
                createdAt: _currentUser!.createdAt,
                dateOfBirth: _currentUser!.dateOfBirth,
                weight: _currentUser!.weight,
                height: _currentUser!.height,
                dailyProtein: _currentUser!.dailyProtein,
                dailyCalories: _currentUser!.dailyCalories,
                avatarPath: savedAvatar,
                onboardingCompleted: _currentUser!.onboardingCompleted,
                topazCoins: _currentUser!.topazCoins,
                bombInventory: _currentUser!.bombInventory,
                scannerDockInventory: _currentUser!.scannerDockInventory,
                defuseGunInventory: _currentUser!.defuseGunInventory,
                nukeInventory: _currentUser!.nukeInventory,
              );
            }
            notifyListeners();
            return true;
          }
        } catch (e) {
          // Token expired/invalid — clear it and fall through to password
          print('Token auto-login failed: $e');
          await _apiService.clearToken();
        }
      }

      // Fallback: stored email + password (legacy / token-less devices)
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
      // Merge locally-saved avatar path in case backend doesn't return it
      if (_currentUser != null && _currentUser!.avatarPath == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedAvatar = prefs.getString('onboarding_avatar');
        if (savedAvatar != null) {
          _currentUser = User(
            id: _currentUser!.id,
            email: _currentUser!.email,
            username: _currentUser!.username,
            totalDistance: _currentUser!.totalDistance,
            territorySize: _currentUser!.territorySize,
            activityStreak: _currentUser!.activityStreak,
            lastActivity: _currentUser!.lastActivity,
            createdAt: _currentUser!.createdAt,
            dateOfBirth: _currentUser!.dateOfBirth,
            weight: _currentUser!.weight,
            height: _currentUser!.height,
            dailyProtein: _currentUser!.dailyProtein,
            dailyCalories: _currentUser!.dailyCalories,
            avatarPath: savedAvatar,
            onboardingCompleted: _currentUser!.onboardingCompleted,
            topazCoins: _currentUser!.topazCoins,
            bombInventory: _currentUser!.bombInventory,
            scannerDockInventory: _currentUser!.scannerDockInventory,
            defuseGunInventory: _currentUser!.defuseGunInventory,
            nukeInventory: _currentUser!.nukeInventory,
          );
        }
      }
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

  /// Reads the locally-saved avatar path (fast, no network).
  Future<String?> getSavedAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('onboarding_avatar');
  }

  Future<bool> saveOnboardingData({
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    double? dailyProtein,
    double? dailyCalories,
    String? avatarPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = <String, dynamic>{'onboardingCompleted': true};

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
      if (dailyCalories != null) {
        prefs.setDouble('onboarding_calories', dailyCalories);
        profileData['dailyCalories'] = dailyCalories;
      }
      if (avatarPath != null) {
        await prefs.setString('onboarding_avatar', avatarPath);
        profileData['avatarPath'] = avatarPath;
        // Update in-memory user so UI updates immediately
        if (_currentUser != null) {
          _currentUser = User(
            id: _currentUser!.id,
            email: _currentUser!.email,
            username: _currentUser!.username,
            totalDistance: _currentUser!.totalDistance,
            territorySize: _currentUser!.territorySize,
            activityStreak: _currentUser!.activityStreak,
            lastActivity: _currentUser!.lastActivity,
            createdAt: _currentUser!.createdAt,
            dateOfBirth: _currentUser!.dateOfBirth,
            weight: _currentUser!.weight,
            height: _currentUser!.height,
            dailyProtein: _currentUser!.dailyProtein,
            dailyCalories: _currentUser!.dailyCalories,
            avatarPath: avatarPath,
            onboardingCompleted: true,
            topazCoins: _currentUser!.topazCoins,
            bombInventory: _currentUser!.bombInventory,
            scannerDockInventory: _currentUser!.scannerDockInventory,
            defuseGunInventory: _currentUser!.defuseGunInventory,
            nukeInventory: _currentUser!.nukeInventory,
          );
        }
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
