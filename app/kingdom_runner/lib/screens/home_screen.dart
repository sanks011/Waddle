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
import 'events_screen.dart';
import 'health_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng _currentPosition = const LatLng(
    22.5726,
    88.3639,
  ); // Kolkata default (will be replaced by GPS)
  bool _isLoadingLocation = true;
  bool _isCalibrating = false;
  int _calibrationReadings = 0;
  double _heading = 0.0; // Compass heading
  int _selectedTab = 2; // 0=Health, 1=Events, 2=Map, 3=Leaderboard, 4=Profile
  final PageController _pageController = PageController(initialPage: 2);

  @override
  void initState() {
    super.initState();
    _initializeOlaMaps();
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

  Future<void> _initializeOlaMaps() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      // Ensure Ola Maps is initialized with auth token
      await OlaMapsConfig.loadFromCache();
      print(
        '🗺️ Ola Maps initialized - API Key loaded: ${OlaMapsConfig.apiKey.isNotEmpty}',
      );
    }
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
    print('📍 Initializing location services...');
    final hasPermission = await _locationService.checkPermissions();

    if (!hasPermission) {
      print('❌ Location permission denied');
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission required for map tracking',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await _locationService.checkPermissions();
              },
            ),
          ),
        );
      }
      return;
    }

    print('✅ Location permission granted, getting current position...');
    final location = await _locationService.getCurrentLocation();

    if (location != null && mounted) {
      print(
        '📍 GPS location obtained: ${location.latitude}, ${location.longitude}',
      );
      setState(() {
        _currentPosition = location;
        _isLoadingLocation = false;
      });
      _mapController.move(_currentPosition, 17);
      await _saveLocation(location);
    } else {
      print('⚠️ Could not get GPS location, using default');
      setState(() {
        _isLoadingLocation = false;
      });
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
  }

  Future<void> _recenterMap() async {
    // Try to get fresh GPS location
    final location = await _locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentPosition = location;
      });
      await _saveLocation(location);
      _mapController.move(_currentPosition, 17);

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 Location updated: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Just recenter to current position
      _mapController.move(_currentPosition, 17);
    }
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
      final user = authProvider.currentUser;
      final avatarPath = user?.avatarPath;
      final primary = Theme.of(context).colorScheme.primary;

      markers.add(
        Marker(
          point: _currentPosition,
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              image: avatarPath != null && avatarPath.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(avatarPath),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: primary,
            ),
            child: avatarPath == null || avatarPath.isEmpty
                ? const Icon(Icons.person_rounded,
                    color: Colors.white, size: 28)
                : null,
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

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _selectedTab = i),
            children: [
              _KeepAlive(child: const HealthScreen()),
              _KeepAlive(child: const EventsScreen()),
              SizedBox.expand(
                child: Stack(
                  children: [
            // Map layer with brighter overlays in dark mode
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: 17,
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
                    urlTemplate: OlaMapsConfig.getTileUrl(isDark: isDarkMode),
                    userAgentPackageName: 'com.example.kingdom_runner',
                    maxZoom: 19,
                    tileSize: 256,
                    // Subdomains for load balancing (CartoDB dark mode)
                    subdomains: isDarkMode
                        ? const ['a', 'b', 'c', 'd']
                        : const ['a', 'b', 'c'],
                    // Enable tile caching
                    tileProvider: NetworkTileProvider(),
                    // Reduce tile loading
                    keepBuffer: 2,
                    panBuffer: 1,
                    errorTileCallback: (tile, error, stackTrace) {
                      // Don't spam console with tile errors
                      if (error.toString().contains('429')) {
                        print(
                          '⚠️ Rate limit reached (switching to OSM recommended)',
                        );
                      }
                    },
                  ),
                  PolygonLayer(polygons: polygons),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
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
                            ? const Color(0xFFE4E4E7).withOpacity(
                                0.95,
                              ) // Bright zinc-200 for map
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFFF4F4F5).withOpacity(
                                  0.6,
                                ) // zinc-100
                              : Colors.white.withOpacity(0.2),
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
                              color: isDarkMode
                                  ? Colors.black87
                                  : Colors.black87,
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
                              children: [
                                Icon(Icons.celebration,
                                    color: Theme.of(context).colorScheme.onPrimary),
                                const SizedBox(width: 12),
                                Text('Territory claimed!',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary)),
                              ],
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else if (activityProvider.currentPath.length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Theme.of(context).colorScheme.onSurface),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Walk more to create a territory (need at least 3 points)',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Theme.of(context).colorScheme.onSurface),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Session saved. Territory area may be too small.',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Theme.of(context).colorScheme.surface,
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
                      colors: _isCalibrating
                          ? [
                              const Color(0xFFD97706),
                              const Color(0xFFB45309),
                            ]
                          : activityProvider.isTracking
                          ? [
                              const Color(0xFFDC2626),
                              const Color(0xFFB91C1C),
                            ]
                          : [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary,
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isCalibrating
                                ? const Color(0xFFD97706)
                                : activityProvider.isTracking
                                    ? const Color(0xFFDC2626)
                                    : Theme.of(context).colorScheme.primary)
                            .withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isCalibrating
                        ? Icons.sensors_rounded
                        : activityProvider.isTracking
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            if (activityProvider.isTracking && !_isCalibrating)
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
                            ? const Color(0xFFE4E4E7).withOpacity(
                                0.95,
                              ) // Bright zinc-200 for map
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFFF4F4F5).withOpacity(
                                  0.5,
                                ) // zinc-100
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
                              Icon(
                                Icons.straighten,
                                size: 28,
                                color: Colors.black87,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatDistance(
                                  activityProvider.currentDistance,
                                ).split(' ')[0],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                formatDistance(
                                  activityProvider.currentDistance,
                                ).split(' ')[1],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.black.withOpacity(0.1),
                          ),
                          Column(
                            children: [
                              Icon(
                                Icons.timeline,
                                size: 28,
                                color: Colors.black87,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${activityProvider.currentPath.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'points',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
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
            if (_isCalibrating)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon with amber glow
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD97706).withOpacity(0.15),
                                    border: Border.all(
                                      color: const Color(0xFFD97706).withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.sensors_rounded,
                                    size: 36,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Calibrating Location',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Walk a few steps so we can\nlock onto your position accurately',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 24),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _calibrationReadings / 5,
                                    minHeight: 8,
                                    backgroundColor: Theme.of(context).dividerColor,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_calibrationReadings} / 5 readings',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 24),
                                // Stop calibration button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      setState(() {
                                        _isCalibrating = false;
                                        _calibrationReadings = 0;
                                      });
                                      // Always stop the session — startSession was already called
                                      await activityProvider.stopSession();
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: const Text('Stop Calibration'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFDC2626)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
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
              ),
                  ],
                ),
              ),
              _KeepAlive(child: const LeaderboardScreen()),
              _KeepAlive(child: const ProfileScreen()),
            ],
          ),
          // Floating dock — always visible on all tabs
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
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
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDockItem(
                            context: context,
                            icon: Icons.water_drop_rounded,
                            isSelected: _selectedTab == 0,
                            onTap: () => _pageController.animateToPage(0,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubic),
                          ),
                          const SizedBox(width: 8),
                          _buildDockItem(
                            context: context,
                            icon: Icons.groups_rounded,
                            isSelected: _selectedTab == 1,
                            onTap: () => _pageController.animateToPage(1,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubic),
                          ),
                          const SizedBox(width: 8),
                          _buildDockItem(
                            context: context,
                            icon: Icons.location_city,
                            isSelected: _selectedTab == 2,
                            onTap: () => _pageController.animateToPage(2,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubic),
                          ),
                          const SizedBox(width: 8),
                          _buildDockItem(
                            context: context,
                            icon: Icons.leaderboard_outlined,
                            isSelected: _selectedTab == 3,
                            onTap: () => _pageController.animateToPage(3,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubic),
                          ),
                          const SizedBox(width: 8),
                          _buildDockItem(
                            context: context,
                            icon: Icons.person_outline_rounded,
                            isSelected: _selectedTab == 4,
                            onTap: () => _pageController.animateToPage(4,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubic),
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
      ),
    );
  }

  Widget _buildDockItem({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: ColorTween(
            begin: onSurface.withOpacity(0.55),
            end: isSelected ? onPrimary : onSurface.withOpacity(0.55),
          ),
          builder: (context, color, child) {
            return Icon(
              icon,
              color: color,
              size: 24,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController.dispose();
    _locationService.dispose();
    super.dispose();
  }
}

// Keeps a PageView child alive so state isn't lost on tab switch
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

