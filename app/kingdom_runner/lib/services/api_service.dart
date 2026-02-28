import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/territory.dart';
import '../models/activity_session.dart';
import 'api_config.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  String? _token;

  Future<String?> get token async {
    _token ??= await storage.read(key: 'auth_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> getHeaders() async {
    await token; // Ensure token is loaded
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Test connectivity to backend
  Future<bool> testConnection() async {
    try {
      print('🔌 Testing connection to ${ApiConfig.baseUrl}/ping');
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/ping'))
          .timeout(const Duration(seconds: 10));

      print('✅ Connection test: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await setToken(data['token']);
      }
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await setToken(data['token']);
      }
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  // User endpoints
  Future<User> getCurrentUser() async {
    await token; // Ensure token is loaded
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userEndpoint}/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      print('👤 User data refreshed: ${user.username}');
      print('📏 Total Distance: ${user.totalDistance}m');
      print('🏰 Territory Size: ${user.territorySize}m²');
      print('🔥 Streak: ${user.activityStreak} days');
      return user;
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  // Territory endpoints
  Future<List<Territory>> getTerritories() async {
    await token;
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.territoryEndpoint}'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final territories = data.map((json) => Territory.fromJson(json)).toList();
      print('🗺️ Loaded ${territories.length} territories');
      return territories;
    } else {
      throw Exception('Failed to load territories: ${response.body}');
    }
  }

  Future<Territory> createTerritory(ActivitySession session) async {
    try {
      await token;
      final headers = await getHeaders();

      print('🌍 Creating territory with ${session.path.length} points');
      print('🔑 Token: ${await this.token != null ? "Present" : "Missing"}');
      print('📡 API URL: ${ApiConfig.baseUrl}${ApiConfig.territoryEndpoint}');
      print(
        '📤 Request body length: ${jsonEncode(session.toJson()).length} bytes',
      );
      print(
        '📍 Path sample: ${session.path.take(3).map((p) => '(${p.latitude}, ${p.longitude})')}',
      );

      final requestBody = jsonEncode(session.toJson());
      print('📦 Full request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.territoryEndpoint}'),
        headers: headers,
        body: requestBody,
      );

      print('📡 Territory creation response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Territory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create territory: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Territory creation error: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Session endpoints
  Future<ActivitySession> createSession(ActivitySession session) async {
    try {
      await token;
      final headers = await getHeaders();

      print('📝 Creating session: ${session.id}');
      print('📡 API URL: ${ApiConfig.baseUrl}${ApiConfig.sessionEndpoint}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sessionEndpoint}'),
        headers: headers,
        body: jsonEncode(session.toJson()),
      );

      print('📡 Create session response: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ActivitySession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create session: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Create session error: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ActivitySession> completeSession(
    String sessionId,
    ActivitySession session,
  ) async {
    try {
      await token;
      final headers = await getHeaders();

      print('🏁 Completing session: $sessionId');
      print(
        '📊 Distance: ${session.distance}m, Points: ${session.path.length}',
      );
      print(
        '📡 API URL: ${ApiConfig.baseUrl}${ApiConfig.sessionEndpoint}/$sessionId/complete',
      );

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.sessionEndpoint}/$sessionId/complete',
        ),
        headers: headers,
        body: jsonEncode(session.toJson()),
      );

      print('📡 Complete session response: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        return ActivitySession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to complete session: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Session completion error: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Leaderboard endpoints
  Future<List<User>> getLeaderboard({String type = 'territory'}) async {
    await token;
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.leaderboardEndpoint}?type=$type',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load leaderboard: ${response.body}');
    }
  }
}
