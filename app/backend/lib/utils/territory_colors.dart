import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/territory.dart';

// ─── Kingdom colour palettes ──────────────────────────────────────────────────
// Each entry: [fillColor, borderColor, shadowColor, glowColor]
const List<List<Color>> _kingdomPalettes = [
  // 0  Crimson Empire
  [Color(0xFFE53935), Color(0xFFB71C1C), Color(0x66B71C1C), Color(0x33E53935)],
  // 1  Royal Azure
  [Color(0xFF1E88E5), Color(0xFF0D47A1), Color(0x660D47A1), Color(0x331E88E5)],
  // 2  Emerald Realm
  [Color(0xFF43A047), Color(0xFF1B5E20), Color(0x661B5E20), Color(0x3343A047)],
  // 3  Golden Domain
  [Color(0xFFFB8C00), Color(0xFFE65100), Color(0x66E65100), Color(0x33FB8C00)],
  // 4  Violet Principality
  [Color(0xFF8E24AA), Color(0xFF4A148C), Color(0x664A148C), Color(0x338E24AA)],
  // 5  Teal Sultanate
  [Color(0xFF00897B), Color(0xFF004D40), Color(0x66004D40), Color(0x3300897B)],
  // 6  Rose Queendom
  [Color(0xFFD81B60), Color(0xFF880E4F), Color(0x66880E4F), Color(0x33D81B60)],
  // 7  Amber Barony
  [Color(0xFFFFB300), Color(0xFFFF6F00), Color(0x66FF6F00), Color(0x33FFB300)],
];

// ─── Data model ───────────────────────────────────────────────────────────────

class TerritoryWithColor {
  final Territory territory;
  final int colorIndex;

  const TerritoryWithColor({required this.territory, required this.colorIndex});

  List<Color> get palette =>
      _kingdomPalettes[colorIndex % _kingdomPalettes.length];

  Color get fillColor => palette[0];
  Color get borderColor => palette[1];
  Color get shadowColor => palette[2];
  Color get glowColor => palette[3];

  /// Semi-transparent fill for polygon interior
  Color get fillFaded => palette[0].withOpacity(0.28);

  /// Slightly stronger fill for the current user's territory
  Color get fillOwner => palette[0].withOpacity(0.45);
}

// ─── Graph-colouring assigner ─────────────────────────────────────────────────

class TerritoryColorAssigner {
  /// Assigns kingdom palette indices using greedy graph-coloring so that
  /// geographically adjacent territories always get different colours.
  static List<TerritoryWithColor> assign(
    List<Territory> territories, {
    double proximityMeters = 300,
  }) {
    final n = territories.length;
    if (n == 0) return [];

    // Build adjacency list
    final adj = List.generate(n, (_) => <int>[]);
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        if (_areAdjacent(territories[i], territories[j], proximityMeters)) {
          adj[i].add(j);
          adj[j].add(i);
        }
      }
    }

    // Greedy coloring
    final colors = List.filled(n, -1);
    for (int i = 0; i < n; i++) {
      final used = <int>{};
      for (final nb in adj[i]) {
        if (colors[nb] >= 0) used.add(colors[nb]);
      }
      int c = 0;
      while (used.contains(c)) c++;
      colors[i] = c;
    }

    return List.generate(
      n,
      (i) =>
          TerritoryWithColor(territory: territories[i], colorIndex: colors[i]),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  static bool _areAdjacent(Territory a, Territory b, double proximityMeters) {
    // Quick bounding-box reject
    if (!_boundsOverlap(a.polygon, b.polygon, proximityMeters)) return false;
    for (final pa in a.polygon) {
      for (final pb in b.polygon) {
        if (_distMeters(pa, pb) < proximityMeters) return true;
      }
    }
    return false;
  }

  static bool _boundsOverlap(
    List<LatLng> a,
    List<LatLng> b,
    double bufferMeters,
  ) {
    if (a.isEmpty || b.isEmpty) return false;
    const deg = 0.000009; // ≈ 1 m
    final buf = deg * bufferMeters;
    final aMinLat = a.map((p) => p.latitude).reduce(min) - buf;
    final aMaxLat = a.map((p) => p.latitude).reduce(max) + buf;
    final aMinLng = a.map((p) => p.longitude).reduce(min) - buf;
    final aMaxLng = a.map((p) => p.longitude).reduce(max) + buf;
    final bMinLat = b.map((p) => p.latitude).reduce(min);
    final bMaxLat = b.map((p) => p.latitude).reduce(max);
    final bMinLng = b.map((p) => p.longitude).reduce(min);
    final bMaxLng = b.map((p) => p.longitude).reduce(max);
    return aMinLat <= bMaxLat &&
        aMaxLat >= bMinLat &&
        aMinLng <= bMaxLng &&
        aMaxLng >= bMinLng;
  }

  static double _distMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final A =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(A), sqrt(1 - A));
  }
}
