import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../models/territory.dart';
import '../models/activity_session.dart';
import '../models/event_room.dart';
import '../models/chat_message.dart';
import 'api_config.dart';

class ApiService {
  static const _timeout = Duration(seconds: 10);

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
    final url = '${ApiConfig.baseUrl}${ApiConfig.authEndpoint}/register';
    print('🌐 REGISTER URL: $url');
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    ).timeout(_timeout, onTimeout: () => throw Exception('Connection timed out. Check your network.'));

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
    ).timeout(_timeout, onTimeout: () => throw Exception('Connection timed out. Check your network.'));

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

  // Update user profile (onboarding data)
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      await token;
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userEndpoint}/me/profile'),
        headers: headers,
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        print('✅ Profile updated successfully');
        return true;
      } else {
        print('⚠️ Profile update failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Profile update error: $e');
      return false;
    }
  }

  // Update user daily calories goal
  Future<User?> updateDailyCalories(double calories) async {
    try {
      await token;
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userEndpoint}/me/profile'),
        headers: headers,
        body: jsonEncode({'dailyCalories': calories}),
      );

      if (response.statusCode == 200) {
        print('✅ Daily calories updated to $calories');
        return User.fromJson(jsonDecode(response.body));
      } else {
        print('⚠️ Calorie update failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Calorie update error: $e');
      return null;
    }
  }

  // Get user activity sessions
  Future<List<ActivitySession>> getUserSessions() async {
    try {
      await token;
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sessionEndpoint}/my'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sessions = data.map((json) => ActivitySession.fromJson(json)).toList();
        print('📊 Loaded ${sessions.length} activity sessions');
        return sessions;
      } else {
        print('⚠️ Failed to load sessions: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Session fetch error: $e');
      return [];
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
        final newTerritory = Territory.fromJson(jsonDecode(response.body));

        // Check for nearby territories to merge
        print('🔍 Checking for nearby territories to merge...');
        await _checkAndMergeTerritories(newTerritory);

        return newTerritory;
      } else {
        throw Exception('Failed to create territory: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Territory creation error: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Territory>> getUserTerritories(String userId) async {
    await token;
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.territoryEndpoint}/user/$userId',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final territories = data.map((json) => Territory.fromJson(json)).toList();
      print('🗺️ Loaded ${territories.length} territories for user $userId');
      return territories;
    } else {
      throw Exception('Failed to load user territories: ${response.body}');
    }
  }

  Future<void> _checkAndMergeTerritories(Territory newTerritory) async {
    try {
      // Get user's territories
      final userId = newTerritory.userId;
      final territories = await getUserTerritories(userId);

      // Check each territory for overlap/proximity
      for (final existingTerritory in territories) {
        if (existingTerritory.id == newTerritory.id) continue;

        // Check if territories are close (within 50 meters)
        final shouldMerge = _shouldMergeTerritories(
          newTerritory,
          existingTerritory,
        );

        if (shouldMerge) {
          print(
            '🤝 Merging territories: ${newTerritory.id} + ${existingTerritory.id}',
          );
          await _mergeTerritories(newTerritory, existingTerritory);
          break; // Only merge once per creation
        }
      }
    } catch (e) {
      print('⚠️ Territory merge check failed: $e');
      // Don't fail territory creation if merge check fails
    }
  }

  bool _shouldMergeTerritories(Territory t1, Territory t2) {
    // Check if any point from t1 is close to any point from t2
    const mergeDistanceMeters = 50.0; // Merge if within 50 meters

    for (final p1 in t1.polygon) {
      for (final p2 in t2.polygon) {
        final distance = _calculateDistanceLatLng(p1, p2);
        if (distance < mergeDistanceMeters) {
          return true;
        }
      }
    }
    return false;
  }

  double _calculateDistanceLatLng(LatLng point1, LatLng point2) {
    const R = 6371000.0; // Earth radius in meters
    final lat1 = point1.latitude * 3.14159 / 180;
    final lat2 = point2.latitude * 3.14159 / 180;
    final dLat = lat2 - lat1;
    final dLon = (point2.longitude - point1.longitude) * 3.14159 / 180;

    final a =
        (dLat / 2) * (dLat / 2) +
        lat1.abs() * lat2.abs() * (dLon / 2) * (dLon / 2);
    final c = 2 * (a.abs());

    return R * c;
  }

  Future<void> _mergeTerritories(
    Territory newTerritory,
    Territory existingTerritory,
  ) async {
    try {
      await token;
      final headers = await getHeaders();

      // Combine polygons from both territories
      final mergedPolygon = [
        ...newTerritory.polygon,
        ...existingTerritory.polygon,
      ];

      // Convert LatLng to map format for API
      final mergedPath = mergedPolygon
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList();

      // Calculate new area (sum of both)
      final mergedArea = newTerritory.area + existingTerritory.area;

      final mergeRequest = {
        'territoryIds': [newTerritory.id, existingTerritory.id],
        'mergedPath': mergedPath,
        'mergedArea': mergedArea,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.territoryEndpoint}/merge'),
        headers: headers,
        body: jsonEncode(mergeRequest),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Territories merged successfully');
      } else {
        print('⚠️ Territory merge failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Territory merge error: $e');
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

  // ─── Events / Rooms ────────────────────────────────────────────────────────

  Future<List<EventRoom>> getEvents({
    double? lat,
    double? lng,
    double radius = 10000,
    String search = '',
  }) async {
    final headers = await getHeaders();
    final queryParams = <String, String>{
      'radius': radius.toString(),
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data = decoded['events'] as List<dynamic>? ?? [];
      return data.map((j) => EventRoom.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load events: ${response.body}');
    }
  }

  Future<EventRoom> getEvent(String eventId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return EventRoom.fromJson(decoded['event'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load event: ${response.body}');
    }
  }

  Future<EventRoom> createEvent({
    required String title,
    String description = '',
    required double lat,
    required double lng,
    required bool isPublic,
    String? password,
  }) async {
    final headers = await getHeaders();
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'lat': lat,
      'lng': lng,
      'isPublic': isPublic,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return EventRoom.fromJson(decoded['event'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create event: ${response.body}');
    }
  }

  Future<EventRoom> joinEvent(String eventId, {String? password}) async {
    final headers = await getHeaders();
    final body = <String, dynamic>{
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId/join',
      ),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return EventRoom.fromJson(decoded['event'] as Map<String, dynamic>);
    } else {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(decoded['error'] ?? decoded['message'] ?? 'Failed to join event');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete event: ${response.body}');
    }
  }

  Future<List<ChatMessage>> getMessages(
    String eventId, {
    String? before,
  }) async {
    final headers = await getHeaders();
    final queryParams = <String, String>{
      if (before != null) 'before': before,
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId/messages',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data = decoded['messages'] as List<dynamic>? ?? [];
      return data
          .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  Future<ChatMessage> sendMessage(String eventId, String content) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}/$eventId/messages',
      ),
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatMessage.fromJson(decoded['message'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
