class OlaMapsConfig {
  // Ola Maps (Krutrim) Configuration
  static const String projectId = 'f91a178a-6a5f-498d-8c08-1ed80a8e638e';
  static const String apiKey = 'AW12ALkUUtywskoKBraA1aWWQMUfNylzH7izgU1e';
  static const String clientId = 'f91a178a-6a5f-498d-8c08-1ed80a8e638e';
  static const String clientSecret = '666f4cb7470045728fe2346d19f10efb';

  // Ola Maps Tile Server URL
  static const String tileUrl =
      'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/{z}/{x}/{y}.png';

  // Ola Maps API Base URL
  static const String baseUrl = 'https://api.olamaps.io';

  // Get tile URL with API key
  static String getTileUrl() {
    return '$tileUrl?api_key=$apiKey';
  }

  // Get headers for API requests
  static Map<String, String> getHeaders() {
    return {'X-API-Key': apiKey, 'Content-Type': 'application/json'};
  }
}
