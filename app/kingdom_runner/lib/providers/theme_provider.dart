import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await _storage.read(key: 'dark_mode');
    _isDarkMode = isDark == 'true';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storage.write(key: 'dark_mode', value: _isDarkMode.toString());
    notifyListeners();
  }

  // ── Light Theme ─────────────────────────────────────────────────────────
  ThemeData get lightTheme => AppTheme.lightTheme;

  // ── Dark Theme ──────────────────────────────────────────────────────────
  ThemeData get darkTheme => AppTheme.darkTheme;
}
