import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Shadcn zinc-50
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF18181B), // Shadcn zinc-900
      secondary: Color(0xFF71717A), // Shadcn zinc-500
      surface: Colors.white,
      background: Color(0xFFFAFAFA),
      error: Color(0xFFEF4444), // Shadcn red-500
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAFAFA),
      foregroundColor: Color(0xFF18181B),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF18181B),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF18181B),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF18181B),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF52525B),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF09090B), // Shadcn zinc-950
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFAFAFA), // Shadcn zinc-50
      secondary: Color(0xFFA1A1AA), // Shadcn zinc-400
      surface: Color(0xFF18181B), // Shadcn zinc-900
      background: Color(0xFF09090B),
      error: Color(0xFFEF4444), // Shadcn red-500
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF09090B),
      foregroundColor: Color(0xFFFAFAFA),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFFAFAFA),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF27272A), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFAFAFA),
        foregroundColor: const Color(0xFF09090B),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFAFAFA),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFFFAFAFA),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFFA1A1AA),
      ),
    ),
  );
}
