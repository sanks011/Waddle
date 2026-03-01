import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Read backend base URL from environment (.env). Falls back to production URL.
  static final String baseUrl = dotenv.env['BACKEND_URL'] ?? 'https://bhago-pro-zszv.onrender.com';

  static const String apiVersion = '/api/v1';

  // Endpoints
  static const String authEndpoint = '$apiVersion/auth';
  static const String userEndpoint = '$apiVersion/users';
  static const String territoryEndpoint = '$apiVersion/territories';
  static const String sessionEndpoint = '$apiVersion/sessions';
  static const String leaderboardEndpoint = '$apiVersion/leaderboard';
  static const String mapsEndpoint = '$apiVersion/maps';
  static const String eventsEndpoint = '$apiVersion/events';
  static const String shopEndpoint = '$apiVersion/shop';
  static const String invasionsEndpoint = '$apiVersion/invasions';
}
