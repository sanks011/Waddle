/// OlaMaps has been fully replaced by Google Maps.
/// This file is a stub for backwards-compatibility only.
library;

class OlaMapsConfig {
  static Future<void> initialize(String authToken) async {}
  static Future<void> loadFromCache() async {}
  static String get apiKey => '';
  static String getTileUrl({bool isDark = false}) => '';
}
