import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../models/territory.dart';
import '../utils/format_utils.dart';
import '../services/google_maps_config.dart';
import '../widgets/kingdom_territory_layer.dart';
import '../utils/kingdom_native_map_generator.dart';

/// Full-screen read-only map that flies to and highlights a single territory.
/// Opened from the territories list in [UserProfileScreen].
class TerritoryMapScreen extends StatefulWidget {
  final Territory territory;
  final int index;

  const TerritoryMapScreen({
    super.key,
    required this.territory,
    required this.index,
  });

  @override
  State<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends State<TerritoryMapScreen> {
  final Completer<gmaps.GoogleMapController> _mapCompleter = Completer();
  gmaps.GoogleMapController? _gMapController;
  bool _lastDarkMode = false;
  late final ValueNotifier<gmaps.CameraPosition> _mapCamera;

  Set<gmaps.Polygon> _territoryPolygons = {};
  Set<gmaps.Marker> _territoryMarkers = {};
  bool _generatorCalled = false;

  @override
  void initState() {
    super.initState();
    final center = _centroid();
    _mapCamera = ValueNotifier(
      gmaps.CameraPosition(
        target: gmaps.LatLng(center.latitude, center.longitude),
        zoom: _fitZoom(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark != _lastDarkMode && _gMapController != null) {
      _lastDarkMode = isDark;
      _gMapController!.setMapStyle(
        isDark ? GoogleMapsConfig.darkMapStyle : null,
      );
    }
  }

  @override
  void dispose() {
    _mapCamera.dispose();
    _gMapController?.dispose();
    super.dispose();
  }

  /// Arithmetic centroid of the territory polygon latlngs.
  LatLng _centroid() {
    final pts = widget.territory.polygon;
    if (pts.isEmpty) return const LatLng(22.5726, 88.3639);
    double lat = 0, lng = 0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / pts.length, lng / pts.length);
  }

  /// Rough zoom level based on the bounding-box diagonal of the polygon.
  double _fitZoom() {
    final pts = widget.territory.polygon;
    if (pts.length < 2) return 16.0;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    // Simple heuristic: smaller bounding box → higher zoom
    final span = (maxLat - minLat).abs() + (maxLng - minLng).abs();
    if (span < 0.001) return 18.0;
    if (span < 0.005) return 17.0;
    if (span < 0.01) return 16.0;
    if (span < 0.05) return 14.0;
    return 13.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final territory = widget.territory;
    final center = _centroid();
    final zoom = _fitZoom();
    final isDark = theme.brightness == Brightness.dark;

    if (!_generatorCalled) {
      _generatorCalled = true;
      KingdomNativeMapGenerator.generate(
        [territory],
        territory.userId, // treat as owner to see castle
      ).then((res) {
        if (mounted) {
          setState(() {
            _territoryPolygons = res.polygons;
            _territoryMarkers = res.markers;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          Positioned.fill(
            child: gmaps.GoogleMap(
              mapType: gmaps.MapType.normal,
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(center.latitude, center.longitude),
                zoom: zoom,
              ),
              onMapCreated: (controller) async {
                _gMapController = controller;
                if (!_mapCompleter.isCompleted) {
                  _mapCompleter.complete(controller);
                }
                _lastDarkMode = isDark;
                if (isDark) {
                  await controller.setMapStyle(GoogleMapsConfig.darkMapStyle);
                }
              },
              onCameraMove: (pos) => _mapCamera.value = pos,
              onTap: (pos) => KingdomTerritoryOverlay.handleMapTap(
                context,
                pos,
                [territory],
                territory.userId,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              polygons: _territoryPolygons,
              markers: _territoryMarkers,
            ),
          ),

          // ── Top bar (frosted-glass) ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 8,
                    right: 16,
                  ),
                  color: (isDark ? Colors.black : Colors.white).withOpacity(
                    0.72,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Territory #${widget.index}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              territory.username,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom info card ──────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.grey[900]! : Colors.white)
                        .withOpacity(0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // drag handle
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Castle icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/castle.svg',
                                height: 28,
                                width: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Territory #${widget.index}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Owner: ${territory.username}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Area badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              formatArea(territory.area),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoChip(
                            context,
                            Icons.calendar_today_rounded,
                            'Created',
                            _shortDate(territory.createdAt),
                          ),
                          _infoChip(
                            context,
                            Icons.update_rounded,
                            'Updated',
                            _shortDate(territory.lastUpdated),
                          ),
                          _infoChip(
                            context,
                            Icons.border_all_rounded,
                            'Points',
                            '${territory.polygon.length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Re-center FAB ─────────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 200,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () => _gMapController?.animateCamera(
                gmaps.CameraUpdate.newCameraPosition(
                  gmaps.CameraPosition(
                    target: gmaps.LatLng(center.latitude, center.longitude),
                    zoom: zoom,
                  ),
                ),
              ),
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              tooltip: 'Re-center',
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  String _shortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
