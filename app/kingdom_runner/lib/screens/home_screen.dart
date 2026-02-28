import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/territory_provider.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../services/ola_maps_config.dart';
import '../utils/format_utils.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng _currentPosition = const LatLng(28.6139, 77.2090); // Delhi default
  int _selectedIndex = 0;
  bool _isLoadingLocation = true;
  bool _isCalibrating = false;
  int _calibrationReadings = 0;

  @override
  void initState() {
    super.initState();
    _loadLastLocation();
    _initializeLocation();
    _loadTerritories();
  }

  Future<void> _loadLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? lat = prefs.getDouble('last_lat');
      final double? lng = prefs.getDouble('last_lng');
      if (lat != null && lng != null) {
        setState(() {
          _currentPosition = LatLng(lat, lng);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition, 15);
      }
    } catch (e) {
      print('Error loading last location: $e');
    }
  }

  Future<void> _saveLocation(LatLng location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', location.latitude);
      await prefs.setDouble('last_lng', location.longitude);
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.checkPermissions();
    if (hasPermission) {
      final location = await _locationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentPosition = location;
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition, 15);
        await _saveLocation(location);
      }

      // Listen to location updates
      _locationService.startTracking((newLocation) {
        if (mounted) {
          // Calibration logic - collect first 5 readings when calibrating
          if (_isCalibrating && _calibrationReadings < 5) {
            _calibrationReadings++;

            if (_calibrationReadings >= 5) {
              // Calibration complete
              setState(() {
                _isCalibrating = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Location calibrated'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              setState(() {});
            }
          }

          setState(() {
            _currentPosition = newLocation;
          });
          _saveLocation(newLocation);

          // Auto-follow user during tracking
          final isTracking = Provider.of<ActivityProvider>(
            context,
            listen: false,
          ).isTracking;
          if (isTracking) {
            _mapController.move(newLocation, _mapController.camera.zoom);
          }
        }
      });
    } else {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _recenterMap() {
    _mapController.move(_currentPosition, 15);
  }

  Future<void> _loadTerritories() async {
    final territoryProvider = Provider.of<TerritoryProvider>(
      context,
      listen: false,
    );
    await territoryProvider.loadTerritories();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final territoryProvider = Provider.of<TerritoryProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Build polygon list
    List<Polygon> polygons = [];
    for (var territory in territoryProvider.territories) {
      if (territory.polygon.length >= 3) {
        final isUserTerritory =
            territory.userId == authProvider.currentUser?.id;
        polygons.add(
          Polygon(
            points: territory.polygon,
            color: isUserTerritory
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderStrokeWidth: 2,
            borderColor: isUserTerritory
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(0.3),
            isFilled: true,
          ),
        );
      }
    }

    // Build polyline for current path
    List<Polyline> polylines = [];
    if (activityProvider.isTracking &&
        activityProvider.currentPath.isNotEmpty) {
      polylines.add(
        Polyline(
          points: activityProvider.currentPath,
          color: Colors.white.withOpacity(0.8),
          strokeWidth: 4,
        ),
      );
    }

    // Build markers
    List<Marker> markers = [];

    // Always show current location marker
    if (!_isLoadingLocation) {
      markers.add(
        Marker(
          point: _currentPosition,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(Icons.circle, color: Colors.white, size: 15),
            ),
          ),
        ),
      );
    }

    if (activityProvider.isTracking &&
        activityProvider.currentPath.isNotEmpty) {
      // Add start marker
      markers.add(
        Marker(
          point: activityProvider.currentPath.first,
          width: 40,
          height: 40,
          child: Icon(
            Icons.flag,
            color: Colors.white.withOpacity(0.8),
            size: 40,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kingdom Runner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 19,
              minZoom: 3,
              maxZoom: 22,
            ),
            children: [
              TileLayer(
                urlTemplate: OlaMapsConfig.getTileUrl(isDark: isDarkMode),
                userAgentPackageName: 'com.example.kingdom_runner',
                maxZoom: 19,
              ),
              PolygonLayer(polygons: polygons),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                attributions: [TextSourceAttribution('Ola Maps', onTap: () {})],
              ),
            ],
          ),
          // Recenter button
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _recenterMap,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.my_location,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (activityProvider.isTracking)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.straighten, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              formatDistance(
                                activityProvider.currentDistance,
                              ).split(' ')[0],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              formatDistance(
                                activityProvider.currentDistance,
                              ).split(' ')[1],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                        ),
                        Column(
                          children: [
                            Icon(Icons.timeline, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '${activityProvider.currentPath.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              'points',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Calibration overlay
          if (_isCalibrating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Calibrating Location',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Walk a few steps to calibrate\nyour location for accuracy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: _calibrationReadings / 5,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_calibrationReadings}/5 readings',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color:
                  ((activityProvider.isTracking || _isCalibrating)
                          ? Colors.red
                          : Colors.green)
                      .withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            if (activityProvider.isTracking || _isCalibrating) {
              // Stop calibration if it was in progress
              if (_isCalibrating) {
                setState(() {
                  _isCalibrating = false;
                  _calibrationReadings = 0;
                });

                // If session hasn't started tracking yet, just stop the session
                if (!activityProvider.isTracking) {
                  await activityProvider.stopSession();
                  return;
                }
              }

              final session = await activityProvider.stopSession();

              if (session != null && mounted) {
                // ALWAYS reload territories and user stats after session ends
                await _loadTerritories();
                await authProvider.loadCurrentUser();

                // Check if territory was created
                if (session.territoryId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.celebration, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Territory claimed!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else if (activityProvider.currentPath.length < 3) {
                  // Not enough points
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Walk more to create a territory (need at least 3 points)',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  // Session completed but no territory
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Session saved. Territory area may be too small.',
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            } else {
              // Start calibration before session
              setState(() {
                _isCalibrating = true;
                _calibrationReadings = 0;
              });

              final success = await activityProvider.startSession(
                authProvider.currentUser?.id ?? '',
              );
              if (!success && mounted) {
                setState(() {
                  _isCalibrating = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Location permission required'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          },
          icon: Icon(
            (activityProvider.isTracking || _isCalibrating)
                ? Icons.stop
                : Icons.play_arrow,
            size: 28,
          ),
          label: Text(
            (activityProvider.isTracking || _isCalibrating) ? 'Stop' : 'Start',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: (activityProvider.isTracking || _isCalibrating)
              ? Colors.red
              : Colors.green,
          elevation: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _locationService.dispose();
    super.dispose();
  }
}
