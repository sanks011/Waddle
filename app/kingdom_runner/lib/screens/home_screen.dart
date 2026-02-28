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
import '../widgets/compass_widget.dart';
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
  bool _isLoadingLocation = true;
  bool _isCalibrating = false;
  int _calibrationReadings = 0;
  double _heading = 0.0; // Compass heading

  @override
  void initState() {
    super.initState();
    _loadLastLocation();
    _initializeLocation();
    _loadTerritories();

    // Set up sensor callbacks
    _locationService.sensorService.onHeadingChanged = (heading) {
      if (mounted) {
        setState(() {
          _heading = heading;
        });
      }
    };

    _locationService.sensorService.onStepDetected = (steps) {
      // Step count tracking - can be used for analytics if needed
    };
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
      backgroundColor: Colors.grey.shade900,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Map layer
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: 19,
                  minZoom: 3,
                  maxZoom: 19,
                  initialRotation: 0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                    rotationThreshold: 15.0,
                    pinchZoomThreshold: 0.3,
                    enableMultiFingerGestureRace: true,
                    rotationWinGestures: MultiFingerGesture.rotate,
                    pinchZoomWinGestures:
                        MultiFingerGesture.pinchZoom |
                        MultiFingerGesture.pinchMove,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDarkMode
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: isDarkMode
                        ? const ['a', 'b', 'c', 'd']
                        : const [],
                    userAgentPackageName: 'com.example.kingdom_runner',
                    maxZoom: 19,
                  ),
                  PolygonLayer(polygons: polygons),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
            // Compass widget
            Positioned(
              top: 50,
              left: 16,
              child: CompassWidget(
                heading: _heading,
                size: 70,
                showDegrees: true,
              ),
            ),
            // Recenter button
            Positioned(
              top: 50,
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
            // Floating Start/Stop button on the right side
            Positioned(
              bottom: 120,
              right: 16,
              child: GestureDetector(
                onTap: () async {
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
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (activityProvider.isTracking || _isCalibrating)
                          ? [
                              const Color(0xFFDC2626), // red-600
                              const Color(0xFFB91C1C), // red-700
                            ]
                          : [
                              const Color(0xFF10B981), // emerald-500
                              const Color(0xFF059669), // emerald-600
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            ((activityProvider.isTracking || _isCalibrating)
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF10B981))
                                .withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    (activityProvider.isTracking || _isCalibrating)
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
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
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
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
            // Floating dock at bottom
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Profile button
                            _buildDockItem(
                              icon: Icons.person_outline_rounded,
                              isSelected: false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(width: 12),
                            // Map icon
                            _buildDockItem(
                              icon: Icons.location_city,
                              isSelected: true,
                              onTap: () {},
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(width: 12),
                            // Leaderboard icon
                            _buildDockItem(
                              icon: Icons.leaderboard_outlined,
                              isSelected: false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LeaderboardScreen(),
                                  ),
                                );
                              },
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
<<<<<<< HEAD
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.white : Colors.black87)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? (isDarkMode ? Colors.black87 : Colors.white)
              : (isDarkMode ? Colors.white : Colors.black87),
          size: 24,
=======
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
>>>>>>> 650255e1b1b204d30e12a5788125563c31b7dffb
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
