class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'https://bhago-pro-jyh0.onrender.com'; // for Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // for iOS simulator
  // static const String baseUrl = 'https://your-backend-url.com'; // for production

  static const String apiVersion = '/api/v1';

  // Endpoints
  static const String authEndpoint = '$apiVersion/auth';
  static const String userEndpoint = '$apiVersion/users';
  static const String territoryEndpoint = '$apiVersion/territories';
  static const String sessionEndpoint = '$apiVersion/sessions';
  static const String leaderboardEndpoint = '$apiVersion/leaderboard';
}
