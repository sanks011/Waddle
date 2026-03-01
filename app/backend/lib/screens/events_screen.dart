import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_room.dart';
import '../services/google_maps_config.dart';
import '../providers/theme_provider.dart';
import '../widgets/create_event_modal.dart';
import '../widgets/event_detail_modal.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final Completer<gmaps.GoogleMapController> _mapCompleter = Completer();
  gmaps.GoogleMapController? _gMapController;
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  LatLng _center = const LatLng(22.5726, 88.3639);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLocationAndEvents();
  }

  Future<void> _loadLocationAndEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat != null && lng != null && mounted) {
      setState(() => _center = LatLng(lat, lng));
      _gMapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), 14),
      );
    }
    await _loadEvents(lat: lat, lng: lng);
  }

  Future<void> _loadEvents({double? lat, double? lng}) async {
    await context.read<EventProvider>().loadEvents(
      lat: lat ?? _center.latitude,
      lng: lng ?? _center.longitude,
      search: _searchQuery,
    );
  }

  @override
  void dispose() {
    _gMapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(EventRoom event) {
    context.read<EventProvider>().openEvent(event);
    showEventDetailModal(context, event);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primary = theme.colorScheme.primary;
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final events = eventProvider.events;

    // Build event markers for Google Maps
    final Set<gmaps.Marker> gmapsMarkers = events.map((e) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(e.id),
        position: gmaps.LatLng(e.location.latitude, e.location.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          e.isPublic
              ? gmaps.BitmapDescriptor.hueGreen
              : gmaps.BitmapDescriptor.hueOrange,
        ),
        infoWindow: gmaps.InfoWindow(title: e.title),
        onTap: () => _openDetail(e),
      );
    }).toSet();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Full-screen Google Map ──
          Positioned.fill(
            child: gmaps.GoogleMap(
              mapType: gmaps.MapType.normal,
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(_center.latitude, _center.longitude),
                zoom: 14,
              ),
              onMapCreated: (controller) async {
                _gMapController = controller;
                if (!_mapCompleter.isCompleted) {
                  _mapCompleter.complete(controller);
                }
                if (isDark) {
                  await controller.setMapStyle(GoogleMapsConfig.darkMapStyle);
                }
              },
              markers: gmapsMarkers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),
          ),

          // ── Events header chip (top-left) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 18, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        'Events',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (events.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${events.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Create FAB (top-right) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                final result = await showCreateEventModal(context);
                if (result == true) _loadLocationAndEvents();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Create',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── DraggableScrollableSheet: search + list ──
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.32,
            minChildSize: 0.12,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.12, 0.32, 0.65, 0.88],
            builder: (ctx, scrollCtrl) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Handle bar
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Sheet header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  events.isEmpty
                                      ? 'No events nearby'
                                      : '${events.length} event${events.length == 1 ? '' : 's'} nearby',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (eventProvider.isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _SearchBar(
                              controller: _searchController,
                              onChanged: (v) {
                                setState(() => _searchQuery = v);
                                _loadEvents();
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    if (events.isEmpty && !eventProvider.isLoading)
                      const SliverToBoxAdapter(child: _EmptyState())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _EventCard(
                            event: events[i],
                            currentUserId: currentUserId,
                            index: i,
                            onTap: () => _openDetail(events[i]),
                          ),
                          childCount: events.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventRoom event;
  final String currentUserId;
  final int index;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.currentUserId,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isCreator = event.creatorId == currentUserId;
    final isJoined = isCreator || event.isParticipant(currentUserId);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + index * 50),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isJoined ? primary.withOpacity(0.35) : theme.dividerColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: event.isPublic ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCreator)
                      _Badge('Host', Colors.amber)
                    else if (isJoined)
                      _Badge('Joined', primary),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.people_outline_rounded,
                      label: '${event.participants.length}',
                      color: primary,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.location_on_outlined,
                      label: event.formattedDistance,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.access_time_rounded,
                      label: event.formattedExpiry,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No events nearby',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create one and invite others!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}
