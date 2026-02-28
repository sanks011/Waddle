class ApiConfig {
  // Production backend URL
  static const String baseUrl = 'https://bhago-pro-jyh0.onrender.com';
  // static const String baseUrl = 'http://10.0.2.2:3000'; // for Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // for iOS simulator

  static const String apiVersion = '/api/v1';

  // Endpoints
  static const String authEndpoint = '$apiVersion/auth';
  static const String userEndpoint = '$apiVersion/users';
  static const String territoryEndpoint = '$apiVersion/territories';
  static const String sessionEndpoint = '$apiVersion/sessions';
  static const String leaderboardEndpoint = '$apiVersion/leaderboard';
  static const String mapsEndpoint = '$apiVersion/maps';
}
