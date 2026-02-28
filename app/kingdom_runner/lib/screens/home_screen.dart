import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/territory_provider.dart';
import '../services/location_service.dart';
import '../services/ola_maps_config.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadTerritories();
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
      }

      // Listen to location updates
      _locationService.startTracking((newLocation) {
        if (mounted &&
            !Provider.of<ActivityProvider>(context, listen: false).isTracking) {
          setState(() {
            _currentPosition = newLocation;
          });
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

    // Build polygon list
    List<Polygon> polygons = [];
    for (var territory in territoryProvider.territories) {
      if (territory.polygon.length >= 3) {
        polygons.add(
          Polygon(
            points: territory.polygon,
            color: territory.userId == authProvider.currentUser?.id
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.2),
            borderStrokeWidth: 2,
            borderColor: territory.userId == authProvider.currentUser?.id
                ? Colors.green
                : Colors.red.withOpacity(0.5),
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
          color: Colors.blue,
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
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 3),
            ),
            child: const Center(
              child: Icon(Icons.circle, color: Colors.blue, size: 15),
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
          child: const Icon(Icons.flag, color: Colors.green, size: 40),
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
              initialZoom: 15,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/{z}/{x}/{y}.png?api_key=${OlaMapsConfig.apiKey}',
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
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          if (activityProvider.isTracking)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Distance: ${(activityProvider.currentDistance / 1000).toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Points: ${activityProvider.currentPath.length}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (activityProvider.isTracking) {
            final session = await activityProvider.stopSession();
            if (session != null && session.formsClosedLoop && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Territory claimed! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
              await _loadTerritories();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Session ended. Complete a loop to claim territory!',
                  ),
                ),
              );
            }
          } else {
            final success = await activityProvider.startSession(
              authProvider.currentUser?.id ?? '',
            );
            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location permission required')),
              );
            }
          }
        },
        icon: Icon(activityProvider.isTracking ? Icons.stop : Icons.play_arrow),
        label: Text(activityProvider.isTracking ? 'Stop' : 'Start'),
        backgroundColor: activityProvider.isTracking
            ? Colors.red
            : Colors.green,
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
