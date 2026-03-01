import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' show Offset;
import '../models/territory.dart';
import '../services/api_service.dart';

/// Simple data class returned by [TerritoryProvider.getMyOverlappingTerritories].
class OverlapInfo {
  final String myTerritoryId;
  final String theirTerritoryId;
  final String theirUsername;
  const OverlapInfo({
    required this.myTerritoryId,
    required this.theirTerritoryId,
    required this.theirUsername,
  });
}

/// Tracks a live invasion of one of the current user's territories.
class TerritoryAttack {
  final String territoryId; // defender's territory ID
  final String?
  attackerTerritoryId; // attacker's territory ID (for intersection rendering)
  final String attackerUsername;
  final DateTime attackedAt;

  TerritoryAttack({
    required this.territoryId,
    this.attackerTerritoryId,
    required this.attackerUsername,
    required this.attackedAt,
  });

  /// 24 hours after the attack began.
  DateTime get reclaimDeadline => attackedAt.add(const Duration(hours: 24));

  /// True when the reclaim window has elapsed.
  bool get isExpired => DateTime.now().isAfter(reclaimDeadline);

  /// Remaining time until the territory is lost (clamped to zero).
  Duration get timeRemaining {
    final remaining = reclaimDeadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() => {
    'territoryId': territoryId,
    'attackerTerritoryId': attackerTerritoryId,
    'attackerUsername': attackerUsername,
    'attackedAt': attackedAt.toIso8601String(),
  };

  factory TerritoryAttack.fromJson(Map<String, dynamic> json) =>
      TerritoryAttack(
        territoryId: json['territoryId'],
        attackerTerritoryId: json['attackerTerritoryId'] as String?,
        attackerUsername: json['attackerUsername'],
        attackedAt: DateTime.parse(json['attackedAt']),
      );
}

/// Represents a permanently conquered overlap zone — the intersection area
/// has transferred FROM [defenderTerritoryId] TO [attackerTerritoryId]
/// because the defender failed to reclaim within 24 hours.
class TerritoryConquest {
  final String defenderTerritoryId;
  final String attackerTerritoryId;
  final String attackerUsername;
  final DateTime conqueredAt;

  TerritoryConquest({
    required this.defenderTerritoryId,
    required this.attackerTerritoryId,
    required this.attackerUsername,
    required this.conqueredAt,
  });

  Map<String, dynamic> toJson() => {
    'defenderTerritoryId': defenderTerritoryId,
    'attackerTerritoryId': attackerTerritoryId,
    'attackerUsername': attackerUsername,
    'conqueredAt': conqueredAt.toIso8601String(),
  };

  factory TerritoryConquest.fromJson(Map<String, dynamic> json) =>
      TerritoryConquest(
        defenderTerritoryId: json['defenderTerritoryId'],
        attackerTerritoryId: json['attackerTerritoryId'],
        attackerUsername: json['attackerUsername'],
        conqueredAt: DateTime.parse(json['conqueredAt']),
      );
}

class TerritoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Territory> _territories = [];
  bool _isLoading = false;
  String? _error;

  // ── Attack state ────────────────────────────────────────────────────────
  // Keyed by defender territoryId; persisted locally via SharedPreferences.
  final Map<String, TerritoryAttack> _attacks = {};

  // ── Conquest state ───────────────────────────────────────────────────────
  // Keyed by defender territoryId; attack expired without reclaim.
  final Map<String, TerritoryConquest> _conquests = {};

  // ── Reclaim grace-period ────────────────────────────────────────────────
  // When a player taps "Defend", the overlap alert is suppressed for 24 h so
  // the card doesn't immediately reappear on the next build.
  final Map<String, DateTime> _reclaimedAt = {};

  List<Territory> get territories => List.unmodifiable(_territories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// All territories currently under attack.
  Map<String, TerritoryAttack> get attacks => Map.unmodifiable(_attacks);

  /// Returns true if [territoryId] was reclaimed within the last 24 hours,
  /// i.e. the overlap alert should be suppressed.
  bool isRecentlyReclaimed(String territoryId) {
    final t = _reclaimedAt[territoryId];
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(hours: 24);
  }

  /// Whether a specific territory is under attack.
  bool isUnderAttack(String territoryId) => _attacks.containsKey(territoryId);

  /// Set of all attacked territory IDs (useful for painter).
  Set<String> get attackedTerritoryIds => _attacks.keys.toSet();

  /// Permanently conquered zones: defender ID → conquest info.
  Map<String, TerritoryConquest> get conquests => Map.unmodifiable(_conquests);

  // ── Server-backed invasion state ──────────────────────────────────────────
  List<Map<String, dynamic>> _serverInvasions = [];

  /// All server-backed invasions involving the current user.
  List<Map<String, dynamic>> get serverInvasions =>
      List.unmodifiable(_serverInvasions);

  /// Active invasions where the current user is the ATTACKER.
  List<Map<String, dynamic>> get myActiveAttacks => _serverInvasions
      .where((i) => i['role'] == 'attacker' && i['status'] == 'active')
      .toList();

  /// Active invasions where the current user is the DEFENDER.
  List<Map<String, dynamic>> get myActiveDefenses => _serverInvasions
      .where((i) => i['role'] == 'defender' && i['status'] == 'active')
      .toList();

  /// Current mode: 'attack', 'defend', or 'idle'.
  String get currentMode {
    if (myActiveDefenses.isNotEmpty) return 'defend';
    if (myActiveAttacks.isNotEmpty) return 'attack';
    return 'idle';
  }

  /// Load invasions from backend.
  Future<void> loadInvasions() async {
    try {
      _serverInvasions = await _apiService.getMyInvasions();
      notifyListeners();
    } catch (e) {
      print('Failed to load invasions: $e');
    }
  }

  /// Report an invasion to the backend (called by attacker).
  Future<void> reportInvasionToBackend(String territoryId) async {
    try {
      await _apiService.reportInvasion(territoryId);
      await loadInvasions(); // refresh
    } catch (e) {
      print('Failed to report invasion to backend: $e');
    }
  }

  /// Defend an invasion via backend (called by defender).
  Future<bool> defendInvasionOnBackend(String invasionId) async {
    try {
      await _apiService.defendInvasion(invasionId);
      await loadInvasions(); // refresh
      return true;
    } catch (e) {
      print('Failed to defend invasion: $e');
      return false;
    }
  }

  // Load territories from cache first, then fetch from API
  Future<void> loadTerritories() async {
    // Load from cache immediately for offline support
    await _loadFromCache();
    await _loadAttacks();
    await _loadConquests();
    await _loadReclaimedAt();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _territories = await _apiService.getTerritories();
      await _saveToCache();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('Failed to load territories from API, using cached data: $e');
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_territories');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _territories = jsonList
            .map((json) => Territory.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading territories from cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(
        _territories.map((t) => t.toJson()).toList(),
      );
      await prefs.setString('cached_territories', jsonData);
    } catch (e) {
      print('Error saving territories to cache: $e');
    }
  }

  List<Territory> getTerritoriesByUser(String userId) {
    return _territories.where((t) => t.userId == userId && t.isActive).toList();
  }

  /// Removes all territories belonging to [userId] from local state, calls
  /// the backend to deactivate them, clears local cache and refreshes.
  Future<void> removeAllUserTerritories(String userId) async {
    // 1. Call backend to deactivate
    try {
      await _apiService.deleteAllUserTerritories();
    } catch (e) {
      print('⚠️ Backend territory deletion failed: $e');
      // Continue with local removal anyway
    }

    // 2. Remove from local list
    _territories = List.from(_territories.where((t) => t.userId != userId));
    await _saveToCache();
    notifyListeners();

    // 3. Refresh from server to stay in sync
    try {
      _territories = await _apiService.getTerritories();
      await _saveToCache();
      notifyListeners();
    } catch (_) {}
  }

  /// Updates bombCount (and optionally bombPositions) for a territory in the
  /// in-memory list and notifies listeners so the map redraws immediately.
  void updateTerritoryBombCount(
    String territoryId,
    int newBombCount, {
    List<LatLng>? newPositions,
  }) {
    final idx = _territories.indexWhere((t) => t.id == territoryId);
    if (idx == -1) return;
    _territories[idx] = _territories[idx].copyWith(
      bombCount: newBombCount,
      bombPositions: newPositions,
    );
    notifyListeners();
  }

  double getTotalAreaByUser(String userId) {
    return getTerritoriesByUser(
      userId,
    ).fold(0.0, (sum, territory) => sum + territory.area);
  }

  // ── Geometric overlap detection ─────────────────────────────────────────

  /// Returns a list of (myTerritoryId, theirTerritoryId, theirUsername) triples
  /// for every territory owned by [userId] that geometrically overlaps with
  /// any other user's territory.  Uses LatLng coordinates as 2-D Offsets for
  /// a fast point-in-polygon test — accurate enough for local overlap queries.
  List<OverlapInfo> getMyOverlappingTerritories(String userId) {
    final myTerritories = getTerritoriesByUser(userId);
    final otherTerritories = _territories
        .where((t) => t.userId != userId && t.isActive && t.polygon.length >= 3)
        .toList();

    final result = <OverlapInfo>[];

    for (final mine in myTerritories) {
      if (mine.polygon.length < 3) continue;
      final myPoly = mine.polygon
          .map((ll) => Offset(ll.longitude, ll.latitude))
          .toList();
      final myHull = _convexHullLatLng(myPoly);

      for (final theirs in otherTerritories) {
        final theirPoly = theirs.polygon
            .map((ll) => Offset(ll.longitude, ll.latitude))
            .toList();
        final theirHull = _convexHullLatLng(theirPoly);

        // Check if any of their hull vertices fall inside my hull or vice versa
        final overlaps =
            theirHull.any((p) => _pointInPolygon(myHull, p)) ||
            myHull.any((p) => _pointInPolygon(theirHull, p));

        if (overlaps) {
          result.add(
            OverlapInfo(
              myTerritoryId: mine.id,
              theirTerritoryId: theirs.id,
              theirUsername: theirs.username,
            ),
          );
          break; // one overlap per my-territory is enough for alerts
        }
      }
    }
    return result;
  }

  /// Simple Graham-scan convex hull on [Offset] list (using lng/lat as x/y).
  static List<Offset> _convexHullLatLng(List<Offset> pts) {
    if (pts.length < 3) return pts;
    final pivot = pts.reduce((a, b) => a.dy > b.dy ? a : b);
    final sorted = List<Offset>.from(pts)
      ..sort((a, b) {
        if (a == pivot) return -1;
        if (b == pivot) return 1;
        final angA = (a - pivot).direction;
        final angB = (b - pivot).direction;
        return angA.compareTo(angB);
      });
    final hull = <Offset>[];
    for (final p in sorted) {
      while (hull.length >= 2) {
        final o = hull[hull.length - 2];
        final a = hull[hull.length - 1];
        final cross =
            (a.dx - o.dx) * (p.dy - o.dy) - (a.dy - o.dy) * (p.dx - o.dx);
        if (cross <= 0) {
          hull.removeLast();
        } else {
          break;
        }
      }
      hull.add(p);
    }
    return hull;
  }

  /// Ray-casting point-in-polygon for LatLng-as-Offset coordinates.
  static bool _pointInPolygon(List<Offset> polygon, Offset point) {
    bool inside = false;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  // ── Attack management ───────────────────────────────────────────────────

  /// Called when an attacker walks into [territoryId].
  /// [territoryId] belongs to the *current device user* whose territory
  /// is being invaded.  [attackerTerritoryId] is the attacker's own territory
  /// (used to render the battle zone intersection on the map).
  void reportAttack(
    String territoryId,
    String attackerUsername, {
    String? attackerTerritoryId,
  }) {
    // Don't overwrite an existing attack that's not yet expired
    if (_attacks.containsKey(territoryId) &&
        !_attacks[territoryId]!.isExpired) {
      return;
    }
    _attacks[territoryId] = TerritoryAttack(
      territoryId: territoryId,
      attackerTerritoryId: attackerTerritoryId,
      attackerUsername: attackerUsername,
      attackedAt: DateTime.now(),
    );
    _saveAttacks();
    notifyListeners();
  }

  /// The owner manually reclaims their territory (or the 24 h window resets).
  /// Also sets a 24 h grace period so the overlap alert card is dismissed.
  void reclaimTerritory(String territoryId) {
    _attacks.remove(territoryId);
    _conquests.remove(territoryId);
    _reclaimedAt[territoryId] = DateTime.now();
    _saveAttacks();
    _saveConquests();
    _saveReclaimedAt();
    notifyListeners();
    print('🛡️ Territory $territoryId reclaimed — alert suppressed for 24 h');
  }

  /// Processes all expired attacks: moves them to [_conquests] so the
  /// intersection area is permanently transferred to the attacker.
  /// Attacks without a known [attackerTerritoryId] are simply removed.
  void processExpiredAttacks() {
    final expired = _attacks.entries.where((e) => e.value.isExpired).toList();
    if (expired.isEmpty) return;
    for (final e in expired) {
      final attack = e.value;
      if (attack.attackerTerritoryId != null) {
        // Only create conquest if attacker territory is known (for visual transfer)
        _conquests[attack.territoryId] = TerritoryConquest(
          defenderTerritoryId: attack.territoryId,
          attackerTerritoryId: attack.attackerTerritoryId!,
          attackerUsername: attack.attackerUsername,
          conqueredAt: DateTime.now(),
        );
      }
      _attacks.remove(e.key);
    }
    _saveAttacks();
    _saveConquests();
    notifyListeners();
  }

  /// Remove any attacks whose 24-hour window has fully elapsed.
  /// Prefer [processExpiredAttacks] for full effect; this is a lightweight
  /// cleanup for cases where attacker territory ID is unavailable.
  void pruneExpiredAttacks() {
    processExpiredAttacks();
  }

  Future<void> _loadAttacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('territory_attacks');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _attacks.clear();
        for (final item in list) {
          final attack = TerritoryAttack.fromJson(item as Map<String, dynamic>);
          if (!attack.isExpired) {
            _attacks[attack.territoryId] = attack;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading attacks from cache: $e');
    }
  }

  Future<void> _saveAttacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _attacks.values.map((a) => a.toJson()).toList();
      await prefs.setString('territory_attacks', jsonEncode(list));
    } catch (e) {
      print('Error saving attacks: $e');
    }
  }

  Future<void> _loadConquests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('territory_conquests');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _conquests.clear();
        for (final item in list) {
          final conquest = TerritoryConquest.fromJson(
            item as Map<String, dynamic>,
          );
          _conquests[conquest.defenderTerritoryId] = conquest;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading conquests from cache: $e');
    }
  }

  Future<void> _saveConquests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _conquests.values.map((c) => c.toJson()).toList();
      await prefs.setString('territory_conquests', jsonEncode(list));
    } catch (e) {
      print('Error saving conquests: $e');
    }
  }

  Future<void> _saveReclaimedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _reclaimedAt.map((k, v) => MapEntry(k, v.toIso8601String()));
      await prefs.setString('territory_reclaimed_at', jsonEncode(map));
    } catch (e) {
      print('Error saving reclaimedAt: $e');
    }
  }

  Future<void> _loadReclaimedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('territory_reclaimed_at');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _reclaimedAt.clear();
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        for (final e in map.entries) {
          final t = DateTime.parse(e.value as String);
          // Only restore if still within the 24 h window
          if (t.isAfter(cutoff)) {
            _reclaimedAt[e.key] = t;
          }
        }
      }
    } catch (e) {
      print('Error loading reclaimedAt: $e');
    }
  }
}
