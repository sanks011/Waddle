import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class OlaMapsConfig {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache for credentials
  static String? _projectId;
  static String? _apiKey;
  static String? _clientId;
  static String? _clientSecret;
  static String? _tileUrl;
  static String? _baseUrl;

  // Fetch credentials from backend (called once on app start)
  static Future<void> initialize(String authToken) async {
    try {
      // Check if already cached
      if (_apiKey != null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mapsEndpoint}/config'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _projectId = data['projectId'];
        _apiKey = data['apiKey'];
        _clientId = data['clientId'];
        _clientSecret = data['clientSecret'];
        _tileUrl = data['tileUrl'];
        _baseUrl = data['baseUrl'];

        // Cache in secure storage for offline use
        await _storage.write(key: 'ola_project_id', value: _projectId);
        await _storage.write(key: 'ola_api_key', value: _apiKey);
        await _storage.write(key: 'ola_client_id', value: _clientId);
        await _storage.write(key: 'ola_client_secret', value: _clientSecret);
        await _storage.write(key: 'ola_tile_url', value: _tileUrl);
        await _storage.write(key: 'ola_base_url', value: _baseUrl);
      } else {
        // Try loading from cache if network fails
        await loadFromCache();
      }
    } catch (e) {
      // Fallback to cached credentials
      await loadFromCache();
    }
  }

  // Load from cache (can be called before login)
  static Future<void> loadFromCache() async {
    _projectId = await _storage.read(key: 'ola_project_id');
    _apiKey = await _storage.read(key: 'ola_api_key');
    _clientId = await _storage.read(key: 'ola_client_id');
    _clientSecret = await _storage.read(key: 'ola_client_secret');
    _tileUrl = await _storage.read(key: 'ola_tile_url');
    _baseUrl = await _storage.read(key: 'ola_base_url');
  }

  static String get projectId => _projectId ?? '';
  static String get apiKey => _apiKey ?? '';
  static String get clientId => _clientId ?? '';
  static String get clientSecret => _clientSecret ?? '';
  static String get tileUrl =>
      _tileUrl ??
      'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/{z}/{x}/{y}.png';
  static String get baseUrl => _baseUrl ?? 'https://api.olamaps.io';

  // Get tile URL with API key (light theme)
  static String getTileUrl({bool isDark = false}) {
    // Use OpenStreetMap/CartoDB as primary provider (no rate limits)
    // Ola Maps has strict rate limiting and causes 429 errors
    return isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    /* Ola Maps - Commented out due to rate limiting (429 errors)
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('⚠️ Ola Maps API key not loaded, using OpenStreetMap fallback');
      return isDark
          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    
    final style = isDark ? 'default-dark-standard' : 'default-light-standard';
    final url =
        'https://api.olamaps.io/tiles/vector/v1/styles/$style/{z}/{x}/{y}.png';
    return '$url?api_key=$apiKey';
    */
  }

  // Get headers for API requests
  static Map<String, String> getHeaders() {
    return {'X-API-Key': apiKey, 'Content-Type': 'application/json'};
  }
}
