import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central access point for the Google Maps API key.
///
/// The key is stored in the project-root `.env` file under the
/// [GOOGLE_MAPS_API_KEY] entry and is read at runtime by flutter_dotenv.
///
/// For Android, the same key is also injected into AndroidManifest.xml
/// at build time by `android/app/build.gradle.kts` reading from `.env`,
/// which is required for the native Google Maps SDK.
class GoogleMapsConfig {
  static String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // ── Dark-mode map style (Google Maps Styling Wizard JSON) ───────────────
  static const String darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill",
   "stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill",
   "stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry",
   "stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill",
   "stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry",
   "stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke",
   "stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill",
   "stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry",
   "stylers":[{"color":"#746855"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke",
   "stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill",
   "stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry",
   "stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill",
   "stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry",
   "stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill",
   "stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke",
   "stylers":[{"color":"#17263c"}]}
]
''';
}
