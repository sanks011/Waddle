import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import '../models/territory.dart';
import '../providers/territory_provider.dart';
import '../utils/territory_colors.dart';
import '../utils/polygon_utils.dart';
import 'territory_stats_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Synchronous Mercator projection: lat/lng → screen Offset
// ═══════════════════════════════════════════════════════════════════════════════

class _MercatorProjection {
  final double _centerX;
  final double _centerY;
  final double _scale;
  final double _cosB;
  final double _sinB;
  final double _halfW;
  final double _halfH;
  final double _centerLat;
  final double _centerLng;
  final double _zoom;
  final double _bearing;

  _MercatorProjection(gmaps.CameraPosition camera, Size size)
    : _scale = pow(2.0, camera.zoom).toDouble() * 256.0,
      _bearing = camera.bearing,
      _cosB = cos(camera.bearing * pi / 180.0),
      _sinB = sin(camera.bearing * pi / 180.0),
      _halfW = size.width / 2.0,
      _halfH = size.height / 2.0,
      _centerLat = camera.target.latitude,
      _centerLng = camera.target.longitude,
      _zoom = camera.zoom,
      _centerX =
          (camera.target.longitude + 180.0) /
          360.0 *
          pow(2.0, camera.zoom).toDouble() *
          256.0,
      _centerY =
          _mercY(camera.target.latitude) *
          pow(2.0, camera.zoom).toDouble() *
          256.0;

  static double _mercY(double lat) {
    final latRad = lat * pi / 180.0;
    return (1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0;
  }

  Offset latLngToScreen(double lat, double lng) {
    final x = (lng + 180.0) / 360.0 * _scale;
    final y = _mercY(lat) * _scale;
    double dx = x - _centerX;
    double dy = y - _centerY;

    if (_bearing != 0) {
      final rdx = dx * _cosB + dy * _sinB;
      final rdy = -dx * _sinB + dy * _cosB;
      dx = rdx;
      dy = rdy;
    }

    return Offset(_halfW + dx, _halfH + dy);
  }

  Offset fromLatLng(LatLng ll) => latLngToScreen(ll.latitude, ll.longitude);

  List<Offset> toOffsets(List<LatLng> points) =>
      points.map((ll) => latLngToScreen(ll.latitude, ll.longitude)).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MercatorProjection &&
          other._centerLat == _centerLat &&
          other._centerLng == _centerLng &&
          other._zoom == _zoom &&
          other._bearing == _bearing &&
          other._halfW == _halfW &&
          other._halfH == _halfH;

  @override
  int get hashCode =>
      Object.hash(_centerLat, _centerLng, _zoom, _bearing, _halfW, _halfH);
}

// ═══════════════════════════════════════════════════════════════════════════════
// KingdomTerritoryOverlay — rich custom-painted territory layer for GoogleMap
// ═══════════════════════════════════════════════════════════════════════════════

/// Overlay widget that renders kingdom-style territories on top of a GoogleMap
/// using CustomPainter with smooth blob shapes, glow borders, doodlish edges,
/// diagonal battle stripes, castle/swords SVG icons, and username labels.
///
/// Place in a [Stack] above the [GoogleMap] and wrap with [IgnorePointer] so
/// map gestures pass through. Connect via [cameraNotifier] (updated from
/// [GoogleMap.onCameraMove]) so the overlay re-projects as the user pans.
///
/// For territory tap handling, call [handleMapTap] from [GoogleMap.onTap].
class KingdomTerritoryOverlay extends StatefulWidget {
  final List<Territory> territories;
  final String currentUserId;
  final Set<String> attackedTerritoryIds;
  final Map<String, TerritoryAttack> battles;
  final Map<String, TerritoryConquest> conquests;
  final ValueNotifier<gmaps.CameraPosition> cameraNotifier;

  const KingdomTerritoryOverlay({
    super.key,
    required this.territories,
    required this.currentUserId,
    required this.cameraNotifier,
    this.attackedTerritoryIds = const {},
    this.battles = const {},
    this.conquests = const {},
  });

  /// Call from [GoogleMap.onTap] to detect territory hits and show the stats
  /// bottom sheet. Hit-test is done in lat/lng space (convex hull ray-cast).
  static void handleMapTap(
    BuildContext context,
    gmaps.LatLng tapPosition,
    List<Territory> territories,
    String currentUserId,
  ) {
    final colored = TerritoryColorAssigner.assign(territories);
    final tapOff = Offset(tapPosition.longitude, tapPosition.latitude);
    for (final ct in colored.reversed) {
      if (ct.territory.polygon.length < 3) continue;
      final pts = ct.territory.polygon
          .map((ll) => Offset(ll.longitude, ll.latitude))
          .toList();
      final hull = PolygonUtils.convexHull(pts);
      if (PolygonUtils.containsPoint(hull, tapOff)) {
        showTerritoryStats(
          context,
          ct.territory,
          ct,
          currentUserId: currentUserId,
        );
        return;
      }
    }
  }

  @override
  State<KingdomTerritoryOverlay> createState() =>
      _KingdomTerritoryOverlayState();
}

class _KingdomTerritoryOverlayState extends State<KingdomTerritoryOverlay>
    with SingleTickerProviderStateMixin {
  late List<TerritoryWithColor> _colored;
  late AnimationController _attackPulseCtrl;
  late Animation<double> _attackPulse;

  @override
  void initState() {
    super.initState();
    _colored = TerritoryColorAssigner.assign(widget.territories);
    _attackPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _attackPulse = CurvedAnimation(
      parent: _attackPulseCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _attackPulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KingdomTerritoryOverlay old) {
    super.didUpdateWidget(old);
    if (old.territories != widget.territories) {
      _colored = TerritoryColorAssigner.assign(widget.territories);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // LayoutBuilder is the only widget-rebuild trigger here — it only fires on
    // actual layout changes (resize), NOT on camera moves or animation ticks.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // ── Territory paint ──────────────────────────────────────────
            // _KingdomPainter carries repaint: Listenable.merge([cameraNotifier,
            // _attackPulse]) so only the RenderCustomPaint node is dirtied on
            // every camera-move / animation tick — NO widget rebuild at all.
            RepaintBoundary(
              child: CustomPaint(
                painter: _KingdomPainter(
                  cameraNotifier: widget.cameraNotifier,
                  attackPulse: _attackPulse,
                  screenSize: size,
                  colored: _colored,
                  currentUserId: widget.currentUserId,
                  isDark: isDark,
                  attackedTerritoryIds: widget.attackedTerritoryIds,
                  battles: widget.battles,
                  conquests: widget.conquests,
                ),
                size: size,
              ),
            ),

            // ── SVG icon overlays (swords / castles / bombs) ─────────────
            // These Positioned widgets DO need to move with the camera, so we
            // wrap them in AnimatedBuilder driven by both listenables. This is
            // cheap because they rebuild instantly without re-running any
            // expensive CustomPainter logic.
            AnimatedBuilder(
              animation: Listenable.merge([
                widget.cameraNotifier,
                _attackPulse,
              ]),
              builder: (context, _) {
                final projection = _MercatorProjection(
                  widget.cameraNotifier.value,
                  size,
                );

                final battleCenters = _computeBattleAndAttackCenters(
                  projection,
                );
                final castlePositions = _computeCastlePositions(projection);
                final bombPositions = _computeBombPositions(projection);

                return Stack(
                  children: [
                    // SVG swords at battle zone centres
                    ...battleCenters.map((entry) {
                      final center = entry.$1;
                      final iconSize = entry.$2;
                      return Positioned(
                        left: center.dx - iconSize / 2,
                        top: center.dy - iconSize / 2,
                        child: IgnorePointer(
                          child: SvgPicture.asset(
                            'assets/security-fight.svg',
                            height: iconSize,
                            width: iconSize,
                          ),
                        ),
                      );
                    }),

                    // Castle icons
                    ...castlePositions.map((entry) {
                      final center = entry.$1;
                      final iconSize = entry.$2;
                      final isOwner = entry.$3;
                      return Positioned(
                        left: center.dx - iconSize / 2,
                        top: center.dy - iconSize / 2,
                        child: IgnorePointer(
                          child: SvgPicture.asset(
                            isOwner
                                ? 'assets/castle.svg'
                                : 'assets/castle2.svg',
                            height: iconSize,
                            width: iconSize,
                          ),
                        ),
                      );
                    }),

                    // Bomb badges
                    ...bombPositions.map((bombScreen) {
                      const badgeSize = 20.0;
                      return Positioned(
                        left: bombScreen.dx - badgeSize / 2,
                        top: bombScreen.dy - badgeSize / 2,
                        child: IgnorePointer(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -4,
                                top: -4,
                                child: Container(
                                  width: badgeSize + 8,
                                  height: badgeSize + 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.15),
                                  ),
                                ),
                              ),
                              SvgPicture.asset(
                                'assets/explosive-bomb.svg',
                                width: badgeSize,
                                height: badgeSize,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SVG overlay position computations
  // ═════════════════════════════════════════════════════════════════════════

  List<(Offset, double)> _computeBattleAndAttackCenters(
    _MercatorProjection proj,
  ) {
    final results = <(Offset, double)>[];

    final Map<String, ui.Path> pathMap = {};
    final Map<String, ({String userId, Offset centroid, double diameter})>
    meta = {};

    for (final ct in _colored) {
      if (ct.territory.polygon.length < 3) continue;
      final rawPoints = proj.toOffsets(ct.territory.polygon);
      final hull = PolygonUtils.convexHull(rawPoints);
      if (hull.length < 3) continue;
      final smooth = PolygonUtils.smoothPolygon(hull, subdivisions: 14);
      pathMap[ct.territory.id] = PolygonUtils.toBezierPath(smooth);
      meta[ct.territory.id] = (
        userId: ct.territory.userId,
        centroid: PolygonUtils.centroid(smooth),
        diameter: PolygonUtils.diameter(smooth),
      );
    }

    final ids = pathMap.keys.toList();

    for (int i = 0; i < ids.length; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        final idA = ids[i];
        final idB = ids[j];
        if (meta[idA]!.userId == meta[idB]!.userId) continue;
        try {
          final intersection = ui.Path.combine(
            ui.PathOperation.intersect,
            pathMap[idA]!,
            pathMap[idB]!,
          );
          final iBounds = intersection.getBounds();
          if (!iBounds.isEmpty && iBounds.width > 8 && iBounds.height > 8) {
            final iconSize = (iBounds.shortestSide * 0.38).clamp(14.0, 34.0);
            results.add((iBounds.center, iconSize));
          }
        } catch (_) {}
      }
    }

    for (final id in ids) {
      if (widget.attackedTerritoryIds.contains(id)) {
        final d = meta[id]!.diameter;
        if (d > 40) {
          results.add((meta[id]!.centroid, (d * 0.22).clamp(14.0, 28.0)));
        }
      }
    }

    return results;
  }

  List<(Offset, double, bool)> _computeCastlePositions(
    _MercatorProjection proj,
  ) {
    final results = <(Offset, double, bool)>[];
    for (final ct in _colored) {
      if (ct.territory.polygon.length < 3) continue;
      final pts = proj.toOffsets(ct.territory.polygon);
      final hull = PolygonUtils.convexHull(pts);
      if (hull.length < 3) continue;
      final centroid = PolygonUtils.centroid(hull);
      final diameter = PolygonUtils.diameter(hull);
      if (diameter <= 40) continue;
      final iconSize = (diameter * 0.22).clamp(14.0, 34.0);
      final isOwner = ct.territory.userId == widget.currentUserId;
      results.add((centroid, iconSize, isOwner));
    }
    return results;
  }

  List<Offset> _computeBombPositions(_MercatorProjection proj) {
    final results = <Offset>[];
    for (final ct in _colored) {
      if (ct.territory.userId != widget.currentUserId) continue;
      if (ct.territory.bombCount <= 0) continue;
      if (ct.territory.polygon.length < 3) continue;

      if (ct.territory.bombPositions.isNotEmpty) {
        for (final bomb in ct.territory.bombPositions) {
          results.add(proj.fromLatLng(bomb));
        }
      } else {
        final pts = proj.toOffsets(ct.territory.polygon);
        final hull = PolygonUtils.convexHull(pts);
        if (hull.length < 3) continue;
        final diameter = PolygonUtils.diameter(hull);
        if (diameter <= 40) continue;
        final centroid = PolygonUtils.centroid(hull);
        results.add(
          Offset(
            centroid.dx + (diameter * 0.13).clamp(10.0, 28.0),
            centroid.dy - (diameter * 0.13).clamp(10.0, 28.0),
          ),
        );
      }
    }
    return results;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _KingdomPainter — rich territory rendering with CustomPainter
// ═══════════════════════════════════════════════════════════════════════════════

class _KingdomPainter extends CustomPainter {
  // Listenables — painter subscribes directly so Flutter can repaint the
  // canvas node without any widget-tree rebuild.
  final ValueNotifier<gmaps.CameraPosition> cameraNotifier;
  final Animation<double> attackPulse;
  final Size screenSize;

  final List<TerritoryWithColor> colored;
  final String currentUserId;
  final bool isDark;
  final Set<String> attackedTerritoryIds;
  final Map<String, TerritoryAttack> battles;
  final Map<String, TerritoryConquest> conquests;

  _KingdomPainter({
    required this.cameraNotifier,
    required this.attackPulse,
    required this.screenSize,
    required this.colored,
    required this.currentUserId,
    required this.isDark,
    this.attackedTerritoryIds = const {},
    this.battles = const {},
    this.conquests = const {},
  }) : super(repaint: Listenable.merge([cameraNotifier, attackPulse]));

  @override
  void paint(Canvas canvas, Size size) {
    // Projection is computed here in paint() directly from the current
    // camera value — no round-trip through the widget tree.
    final projection = _MercatorProjection(cameraNotifier.value, size);
    final pulse = attackPulse.value;

    // ── Phase 1: Pre-compute smooth paths for every territory ─────────────
    final Map<String, List<Offset>> smoothMap = {};
    final Map<String, ui.Path> pathMap = {};

    for (final ct in colored) {
      if (ct.territory.polygon.length < 3) continue;
      final rawPoints = projection.toOffsets(ct.territory.polygon);
      final hull = PolygonUtils.convexHull(rawPoints);
      if (hull.length < 3) continue;
      final smooth = PolygonUtils.smoothPolygon(hull, subdivisions: 14);
      smoothMap[ct.territory.id] = smooth;
      pathMap[ct.territory.id] = PolygonUtils.toBezierPath(smooth);
    }

    // ── Phase 2: Sort so current user's territory is drawn LAST (on top) ──
    final sorted = [...colored]
      ..sort((a, b) {
        final aIsOwner = a.territory.userId == currentUserId ? 1 : 0;
        final bIsOwner = b.territory.userId == currentUserId ? 1 : 0;
        if (aIsOwner != bIsOwner) return aIsOwner - bIsOwner;

        final aConqueredB =
            conquests.containsKey(b.territory.id) &&
            conquests[b.territory.id]!.attackerTerritoryId == a.territory.id;
        final bConqueredA =
            conquests.containsKey(a.territory.id) &&
            conquests[a.territory.id]!.attackerTerritoryId == b.territory.id;
        if (aConqueredB) return 1;
        if (bConqueredA) return -1;

        return a.territory.id.compareTo(b.territory.id);
      });

    // ── Phase 3: Draw each territory, clipping out higher-ranked fills ────
    for (int i = 0; i < sorted.length; i++) {
      final ct = sorted[i];
      final id = ct.territory.id;
      if (!smoothMap.containsKey(id)) continue;

      final smooth = smoothMap[id]!;
      final myPath = pathMap[id]!;

      final exclusionPath = ui.Path();
      for (int j = i + 1; j < sorted.length; j++) {
        final otherId = sorted[j].territory.id;
        if (pathMap.containsKey(otherId)) {
          exclusionPath.addPath(pathMap[otherId]!, Offset.zero);
        }
      }

      _drawTerritoryWithExclusion(canvas, ct, smooth, myPath, exclusionPath);
    }

    // ── Phase 4: Auto-detect geometric intersections → battle zones ───────
    for (int i = 0; i < sorted.length; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        final idA = sorted[i].territory.id;
        final idB = sorted[j].territory.id;
        if (sorted[i].territory.userId == sorted[j].territory.userId) continue;
        final pathA = pathMap[idA];
        final pathB = pathMap[idB];
        if (pathA == null || pathB == null) continue;

        try {
          final intersection = ui.Path.combine(
            ui.PathOperation.intersect,
            pathA,
            pathB,
          );
          final iBounds = intersection.getBounds();
          if (!iBounds.isEmpty && iBounds.width > 8 && iBounds.height > 8) {
            final TerritoryAttack? attack = battles[idA] ?? battles[idB];
            _drawBattleZone(canvas, intersection, pulse, attack);
          }
        } catch (_) {}
      }
    }

    // ── Phase 5: Castle labels drawn LAST (above all fills) ───────────────
    for (final ct in sorted) {
      final id = ct.territory.id;
      if (!smoothMap.containsKey(id)) continue;
      final smooth = smoothMap[id]!;
      final diameter = PolygonUtils.diameter(smooth);
      if (diameter > 40) {
        _drawCastleLabel(canvas, PolygonUtils.centroid(smooth), ct, diameter);
      }
    }
  }

  // ─── Territory body (shadow + extrusion + fill + border) ────────────────

  void _drawTerritoryWithExclusion(
    Canvas canvas,
    TerritoryWithColor ct,
    List<Offset> smooth,
    ui.Path myPath,
    ui.Path exclusionPath,
  ) {
    final isOwner = ct.territory.userId == currentUserId;
    final isAttacked = attackedTerritoryIds.contains(ct.territory.id);
    final seed = ct.territory.id.hashCode;
    final rawDiameter = PolygonUtils.diameter(smooth);
    final centroid = PolygonUtils.centroid(smooth);
    final hasExclusion = !exclusionPath.getBounds().isEmpty;

    // Shadow + extrusion + fill in a saveLayer so dstOut works
    canvas.saveLayer(myPath.getBounds().inflate(22), Paint());

    _drawShadow(canvas, smooth, ct, isOwner);
    _drawExtrusion(canvas, smooth, ct);
    _drawFill(canvas, smooth, ct, isOwner, isAttacked);

    // Punch out higher-priority territories
    if (hasExclusion) {
      canvas.drawPath(
        exclusionPath,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();

    // Borders + labels drawn ABOVE clipping
    _drawDoodlishBorder(canvas, smooth, ct, seed);
    if (isAttacked) {
      // pulse is the local variable captured from paint() via attackPulse.value
      _drawAttackPulse(canvas, smooth, attackPulse.value);
    }
    _drawHighlight(canvas, smooth, ct);
    if (rawDiameter > 40) {
      _drawCastleGlow(canvas, centroid, ct, rawDiameter);
    }
  }

  // ─── Attack pulse border ───────────────────────────────────────────────

  void _drawAttackPulse(Canvas canvas, List<Offset> smooth, double pulse) {
    final path = PolygonUtils.toBezierPath(smooth);
    // Outer pulsing glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.25 + 0.35 * pulse)
        ..strokeWidth = 8 + 6 * pulse
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 4 * pulse),
    );
    // Sharp inner warning stripe
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.70 + 0.28 * pulse)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ─── Battle zone (intersection conflict area) ─────────────────────────

  void _drawBattleZone(
    Canvas canvas,
    ui.Path intersection,
    double pulse,
    TerritoryAttack? attack,
  ) {
    final bounds = intersection.getBounds();
    if (bounds.isEmpty) return;
    final center = bounds.center;

    // 1. Flickering orange-red fill
    canvas.drawPath(
      intersection,
      Paint()
        ..shader = ui.Gradient.radial(center, bounds.longestSide * 0.65, [
          const Color(0xFFFF6B00).withOpacity(0.55 + 0.28 * pulse),
          const Color(0xFFEF4444).withOpacity(0.35 + 0.20 * pulse),
        ])
        ..style = PaintingStyle.fill,
    );

    // 2. Diagonal battle stripes
    canvas.save();
    canvas.clipPath(intersection);
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.10 + 0.06 * pulse)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    const stripeGap = 14.0;
    final diag = bounds.width + bounds.height;
    for (double d = -diag; d < diag; d += stripeGap) {
      canvas.drawLine(
        Offset(bounds.left + d, bounds.top),
        Offset(bounds.left + d + diag, bounds.top + diag),
        stripePaint,
      );
    }
    canvas.restore();

    // 3. Pulsing border
    canvas.drawPath(
      intersection,
      Paint()
        ..color = const Color(0xFFFF6B00).withOpacity(0.90 + 0.10 * pulse)
        ..strokeWidth = 2.5 + 1.5 * pulse
        ..style = PaintingStyle.stroke
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3 + 3 * pulse)
        ..strokeJoin = StrokeJoin.round,
    );

    // 4. Sparks (random pulsing dots along border)
    final rng = Random(attack?.territoryId.hashCode ?? bounds.center.hashCode);
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFF176).withOpacity(0.75 + 0.25 * pulse)
      ..style = PaintingStyle.fill;
    for (int s = 0; s < 8; s++) {
      final angle = rng.nextDouble() * 2 * pi;
      final radius =
          bounds.shortestSide * 0.35 +
          rng.nextDouble() * bounds.shortestSide * 0.15;
      final sparkPos =
          center + Offset(cos(angle) * radius, sin(angle) * radius);
      if (intersection.contains(sparkPos)) {
        canvas.drawCircle(sparkPos, 2.0 + 1.5 * pulse, sparkPaint);
      } else {
        canvas.drawCircle(
          sparkPos,
          1.5,
          sparkPaint..color = sparkPaint.color.withOpacity(0.40),
        );
      }
    }

    // 5. Glowing background circle (SVG icon overlaid by Stack above)
    final iconSize = (bounds.shortestSide * 0.38).clamp(12.0, 36.0);
    canvas.drawCircle(
      center,
      iconSize * 0.78 + 2.0 * pulse,
      Paint()
        ..color = const Color(0xFF7F1D1D).withOpacity(0.78 + 0.18 * pulse)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5 + 3 * pulse),
    );

    // 6. Countdown timer pill (only when attack is tracked)
    if (attack != null && bounds.shortestSide > 50) {
      final remaining = attack.timeRemaining;
      final hours = remaining.inHours;
      final mins = remaining.inMinutes % 60;
      final timeText = hours > 0 ? '${hours}h ${mins}m left' : '${mins}m left';

      final timeFontSize = (bounds.shortestSide * 0.11).clamp(7.0, 11.0);
      final timeTp = TextPainter(
        text: TextSpan(
          text: timeText,
          style: TextStyle(
            fontSize: timeFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillY = center.dy + iconSize * 0.62;
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, pillY + timeTp.height / 2),
          width: timeTp.width + 14,
          height: timeTp.height + 7,
        ),
        const Radius.circular(20),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = const Color(0xFF7F1D1D).withOpacity(0.88),
      );
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
      timeTp.paint(canvas, Offset(center.dx - timeTp.width / 2, pillY));
    }
  }

  // ─── Shadow / glow under territory ─────────────────────────────────────

  void _drawShadow(
    Canvas canvas,
    List<Offset> smooth,
    TerritoryWithColor ct,
    bool isOwner,
  ) {
    final path = PolygonUtils.toBezierPath(smooth);
    final paint = Paint()
      ..color = ct.shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isOwner ? 16 : 10);
    canvas.save();
    canvas.translate(3, 5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  // ─── Pseudo-3D extrusion (wall effect) ─────────────────────────────────

  void _drawExtrusion(
    Canvas canvas,
    List<Offset> smooth,
    TerritoryWithColor ct,
  ) {
    const extrusionPx = 4.0;
    final shiftedPoints = smooth
        .map((p) => p + const Offset(extrusionPx, extrusionPx))
        .toList();
    final path = PolygonUtils.toBezierPath(shiftedPoints);

    final paint = Paint()
      ..color = ct.borderColor.withOpacity(0.30)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Subtle wall lines
    final wallPaint = Paint()
      ..color = ct.borderColor.withOpacity(0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < smooth.length; i += max(1, smooth.length ~/ 18)) {
      canvas.drawLine(
        smooth[i],
        smooth[i] + const Offset(extrusionPx, extrusionPx),
        wallPaint,
      );
    }
  }

  // ─── Main polygon fill ────────────────────────────────────────────────

  void _drawFill(
    Canvas canvas,
    List<Offset> smooth,
    TerritoryWithColor ct,
    bool isOwner,
    bool isAttacked,
  ) {
    final path = PolygonUtils.toBezierPath(smooth);
    final centroid = PolygonUtils.centroid(smooth);
    final diameter = PolygonUtils.diameter(smooth);

    final fillColor = isAttacked ? const Color(0xFFEF4444) : ct.fillColor;
    final rimColor = isAttacked ? const Color(0xFFB91C1C) : ct.borderColor;
    final baseOpacity = isAttacked ? 0.30 : (isOwner ? 0.38 : 0.22);
    final rimOpacity = isAttacked ? 0.20 : (isOwner ? 0.28 : 0.14);

    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(centroid, diameter * 0.65, [
        fillColor.withOpacity(baseOpacity),
        rimColor.withOpacity(rimOpacity),
      ])
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Doodlish hatching texture
    _drawHatching(canvas, path, ct);
  }

  void _drawHatching(Canvas canvas, ui.Path clipPath, TerritoryWithColor ct) {
    final hatchPaint = Paint()
      ..color = ct.fillColor.withOpacity(0.06)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipPath(clipPath);

    final bounds = clipPath.getBounds();
    const step = 14.0;
    final diag = (bounds.width + bounds.height);
    for (double d = -diag; d < diag; d += step) {
      canvas.drawLine(
        Offset(bounds.left + d, bounds.top),
        Offset(bounds.left + d + diag, bounds.top + diag),
        hatchPaint,
      );
    }
    canvas.restore();
  }

  // ─── Doodlish / hand-drawn border ─────────────────────────────────────

  void _drawDoodlishBorder(
    Canvas canvas,
    List<Offset> smooth,
    TerritoryWithColor ct,
    int seed,
  ) {
    final bezierPath = PolygonUtils.toBezierPath(smooth);

    // Pass 1: outer glow stroke
    canvas.drawPath(
      bezierPath,
      Paint()
        ..color = ct.borderColor.withOpacity(0.55)
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // Pass 2: doodlish jittered border
    final outer = PolygonUtils.doodlize(smooth, seed, amount: 1.8);
    canvas.drawPath(
      PolygonUtils.toBezierPath(outer),
      Paint()
        ..color = ct.borderColor.withOpacity(0.88)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Pass 3: thin secondary sketch line
    final inner = PolygonUtils.doodlize(smooth, seed + 1, amount: 1.0);
    canvas.drawPath(
      PolygonUtils.toBezierPath(inner),
      Paint()
        ..color = ct.borderColor.withOpacity(0.38)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Pass 4: dots for marker-pen feel
    final dotPaint = Paint()
      ..color = ct.borderColor.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final rng = Random(seed + 2);
    for (int i = 0; i < smooth.length; i += max(1, smooth.length ~/ 28)) {
      final jitter = Offset(
        (rng.nextDouble() - 0.5) * 2,
        (rng.nextDouble() - 0.5) * 2,
      );
      canvas.drawCircle(smooth[i] + jitter, 1.4, dotPaint);
    }
  }

  // ─── Top highlight shimmer ────────────────────────────────────────────

  void _drawHighlight(
    Canvas canvas,
    List<Offset> smooth,
    TerritoryWithColor ct,
  ) {
    canvas.drawPath(
      PolygonUtils.toBezierPath(smooth),
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ─── Castle glow circle ───────────────────────────────────────────────

  void _drawCastleGlow(
    Canvas canvas,
    Offset centroid,
    TerritoryWithColor ct,
    double diameter,
  ) {
    final iconSize = (diameter * 0.22).clamp(14.0, 34.0);
    canvas.drawCircle(
      centroid,
      iconSize * 0.72,
      Paint()
        ..color = ct.fillColor.withOpacity(0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  // ─── Username label (Phase 5 — above all territory fills) ─────────────

  void _drawCastleLabel(
    Canvas canvas,
    Offset centroid,
    TerritoryWithColor ct,
    double diameter,
  ) {
    if (diameter <= 70) return;
    final iconSize = (diameter * 0.22).clamp(14.0, 34.0);
    final labelFontSize = (diameter * 0.055).clamp(8.0, 13.0);

    final labelTp = TextPainter(
      text: TextSpan(
        text: ct.territory.username,
        style: TextStyle(
          fontSize: labelFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: ct.borderColor,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelY = centroid.dy + iconSize * 0.52;
    final labelX = centroid.dx - labelTp.width / 2;

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelX - 6,
        labelY - 2,
        labelTp.width + 12,
        labelTp.height + 4,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = ct.borderColor.withOpacity(0.82)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
    labelTp.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(_KingdomPainter old) =>
      // Camera + animation repaints are driven by the repaint listenable, so
      // shouldRepaint only needs to catch data changes (territory list, user,
      // theme, etc.).
      old.cameraNotifier != cameraNotifier ||
      old.attackPulse != attackPulse ||
      old.screenSize != screenSize ||
      old.colored != colored ||
      old.currentUserId != currentUserId ||
      old.isDark != isDark ||
      old.attackedTerritoryIds != attackedTerritoryIds ||
      old.battles != battles ||
      old.conquests != conquests;
}
