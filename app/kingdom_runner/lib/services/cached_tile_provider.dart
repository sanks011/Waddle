/// This file is a stub kept for import backwards-compatibility.
/// The two-level tile cache was only needed for the old OpenStreetMap /
/// CartoDB tile provider.  Google Maps SDK handles tile caching internally,
/// so no manual caching is required.
library;

/// Stub class - no longer functional.
class CachedTileProvider {
  /// No-op initializer.
  static Future<void> init() async {}
}
