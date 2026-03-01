import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../models/territory.dart';
import '../utils/polygon_utils.dart';
import '../utils/territory_colors.dart';

class KingdomNativeOverrides {
  final Set<gmaps.Polygon> polygons;
  final Set<gmaps.Marker> markers;
  KingdomNativeOverrides(this.polygons, this.markers);
}

class KingdomNativeMapGenerator {
  // SVG bitmap cache so we don't re-render every frame
  static final Map<String, gmaps.BitmapDescriptor> _bitmapCache = {};

  /// Renders an SVG asset file into a [gmaps.BitmapDescriptor].
  static Future<gmaps.BitmapDescriptor> _svgToBitmap(
    String assetPath,
    double size, {
    String? cacheKey,
  }) async {
    final key = cacheKey ?? '$assetPath@$size';
    if (_bitmapCache.containsKey(key)) return _bitmapCache[key]!;

    // Load the SVG string from assets
    final svgString = await rootBundle.loadString(assetPath);

    // Use vg.loadPicture for flutter_svg v2
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcW = pictureInfo.size.width;
    final srcH = pictureInfo.size.height;
    final scale = size / max(srcW, srcH);

    canvas.save();
    canvas.scale(scale, scale);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();

    final outW = (srcW * scale).ceil().clamp(1, 512);
    final outH = (srcH * scale).ceil().clamp(1, 512);

    final picture = recorder.endRecording();
    final image = await picture.toImage(outW, outH);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    pictureInfo.picture.dispose();
    image.dispose();

    final descriptor = gmaps.BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
    );
    _bitmapCache[key] = descriptor;
    return descriptor;
  }

  /// Creates a combined bitmap: username pill on top + castle SVG below.
  static Future<gmaps.BitmapDescriptor> _createCastleWithLabel(
    String username,
    Color borderColor,
    bool isOwner,
  ) async {
    final key = 'cstl_${username}_${borderColor.value}_$isOwner';
    if (_bitmapCache.containsKey(key)) return _bitmapCache[key]!;

    // ── 1. Load the castle SVG ──
    final svgAsset = isOwner ? 'assets/castle.svg' : 'assets/castle2.svg';
    final svgString = await rootBundle.loadString(svgAsset);
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    const double svgSize = 38;
    final srcW = pictureInfo.size.width;
    final srcH = pictureInfo.size.height;
    final svgScale = svgSize / max(srcW, srcH);
    final svgW = (srcW * svgScale).ceilToDouble();
    final svgH = (srcH * svgScale).ceilToDouble();

    // ── 2. Measure the username text ──
    final namePainter = TextPainter(textDirection: TextDirection.ltr);
    namePainter.text = TextSpan(
      text: username,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(color: borderColor, blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
    );
    namePainter.layout();

    final pillW = namePainter.width + 14;
    final pillH = namePainter.height + 6;
    const gap = 3.0; // gap between pill and castle

    // ── 3. Canvas that fits both ──
    final totalW = max(pillW, svgW) + 4; // 4px padding
    final totalH = pillH + gap + svgH + 4;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // ── 4. Draw username pill at top center ──
    final pillX = (totalW - pillW) / 2;
    const pillY = 2.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillX, pillY, pillW, pillH),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = borderColor.withOpacity(0.88)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = Colors.white.withOpacity(0.40)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
    namePainter.paint(canvas, Offset(pillX + 7, pillY + 3));

    // ── 5. Draw castle SVG below the pill ──
    final svgX = (totalW - svgW) / 2;
    final svgY = pillY + pillH + gap;
    canvas.save();
    canvas.translate(svgX, svgY);
    canvas.scale(svgScale, svgScale);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
    pictureInfo.picture.dispose();

    // ── 6. Finalize ──
    final picture = recorder.endRecording();
    final image = await picture.toImage(totalW.ceil(), totalH.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final descriptor = gmaps.BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
    );
    _bitmapCache[key] = descriptor;
    return descriptor;
  }

  /// Creates a "⚔ WAR ZONE" label bitmap for battle overlap areas.
  static Future<gmaps.BitmapDescriptor> _createWarZoneLabel() async {
    const key = 'war_zone_label';
    if (_bitmapCache.containsKey(key)) return _bitmapCache[key]!;

    // ── 1. Load fight SVG ──
    final svgString = await rootBundle.loadString('assets/security-fight.svg');
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    const double iconSize = 28;
    final srcW = pictureInfo.size.width;
    final srcH = pictureInfo.size.height;
    final svgScale = iconSize / max(srcW, srcH);
    final iconW = (srcW * svgScale).ceilToDouble();
    final iconH = (srcH * svgScale).ceilToDouble();

    // ── 2. Measure text ──
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'WAR ZONE',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.2,
        shadows: [
          Shadow(color: Color(0xFFFF6B00), blurRadius: 4),
          Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
    textPainter.layout();

    final textW = textPainter.width;
    final textH = textPainter.height;
    const pad = 8.0;
    const gap = 3.0;

    final pillW = textW + pad * 2;
    final pillH = textH + 6;
    final totalW = max(pillW, iconW) + 4;
    final totalH = iconH + gap + pillH + 4;

    // ── 3. Paint ──
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // SVG icon at top center
    final iconX = (totalW - iconW) / 2;
    const iconY = 2.0;
    canvas.save();
    canvas.translate(iconX, iconY);
    canvas.scale(svgScale, svgScale);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
    pictureInfo.picture.dispose();

    // "WAR ZONE" pill below icon
    final pillX = (totalW - pillW) / 2;
    final pillY = iconY + iconH + gap;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillX, pillY, pillW, pillH),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = const Color(0xFFFF6B00).withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
    textPainter.paint(canvas, Offset(pillX + pad, pillY + 3));

    // ── 4. Finalize ──
    final picture = recorder.endRecording();
    final image = await picture.toImage(totalW.ceil(), totalH.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final descriptor = gmaps.BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
    );
    _bitmapCache[key] = descriptor;
    return descriptor;
  }

  static Future<KingdomNativeOverrides> generate(
    List<Territory> territories,
    String currentUserId, {
    Set<String> attackedTerritoryIds = const {},
    void Function(String territoryId)? onCastleTap,
  }) async {
    final Map<String, TerritoryWithColor> colored = {};
    for (final ct in TerritoryColorAssigner.assign(territories)) {
      colored[ct.territory.id] = ct;
    }

    final polygons = <gmaps.Polygon>{};
    final markers = <gmaps.Marker>{};

    // Pre-compute smoothed polygons for all territories
    final Map<String, List<gmaps.LatLng>> smoothedMap = {};
    final Map<String, (double, double, double)> projMap = {};
    final Map<String, List<Offset>> hullCache = {};

    for (final ct in colored.values) {
      if (ct.territory.polygon.length < 3) continue;

      double sumLat = 0, sumLng = 0;
      for (final l in ct.territory.polygon) {
        sumLat += l.latitude;
        sumLng += l.longitude;
      }
      final cLat = sumLat / ct.territory.polygon.length;
      final cLng = sumLng / ct.territory.polygon.length;
      final cosLat = cos(cLat * pi / 180.0);
      projMap[ct.territory.id] = (cLat, cLng, cosLat);

      List<Offset> pts = ct.territory.polygon.map((l) {
        return Offset((l.longitude - cLng) * cosLat, l.latitude - cLat);
      }).toList();

      final hull = PolygonUtils.convexHull(pts);
      if (hull.length < 3) continue;
      hullCache[ct.territory.id] = hull;
      final smoothPts = PolygonUtils.smoothPolygon(hull, subdivisions: 4);

      final smoothMapPts = smoothPts.map((o) {
        return gmaps.LatLng(o.dy + cLat, (o.dx / cosLat) + cLng);
      }).toList();

      smoothedMap[ct.territory.id] = smoothMapPts;
    }

    // Pre-load SVG bitmaps
    final bombBmp = await _svgToBitmap(
      'assets/explosive-bomb.svg',
      24,
      cacheKey: 'bomb_24',
    );

    // Draw territory polygons and markers
    for (final ct in colored.values) {
      final id = ct.territory.id;
      if (!smoothedMap.containsKey(id)) continue;
      final smoothMapPts = smoothedMap[id]!;
      final proj = projMap[id]!;
      final cLat = proj.$1;
      final cLng = proj.$2;
      final cosLat = proj.$3;

      final isOwner = ct.territory.userId == currentUserId;
      final isAttacked = attackedTerritoryIds.contains(id);

      final fillColor = isAttacked ? const Color(0xFFEF4444) : ct.fillColor;
      final strokeColor = isAttacked ? const Color(0xFFB91C1C) : ct.borderColor;

      // ── Single polygon: fill + stroke (wall) ──
      polygons.add(
        gmaps.Polygon(
          polygonId: gmaps.PolygonId(id),
          points: smoothMapPts,
          fillColor: fillColor.withOpacity(isOwner ? 0.35 : 0.22),
          strokeColor: _darken(strokeColor, 0.25).withOpacity(0.90),
          strokeWidth: 4,
          zIndex: 2,
        ),
      );

      // Bomb SVG markers (non-castle, placed first pass)
      if (isOwner && ct.territory.bombCount > 0) {
        final hull = hullCache[id]!;
        final diameterDeg = PolygonUtils.diameter(hull);

        if (ct.territory.bombPositions.isNotEmpty) {
          int bIdx = 0;
          for (final bombLatLng in ct.territory.bombPositions) {
            markers.add(
              gmaps.Marker(
                markerId: gmaps.MarkerId('bomb_${id}_$bIdx'),
                position: gmaps.LatLng(
                  bombLatLng.latitude,
                  bombLatLng.longitude,
                ),
                icon: bombBmp,
                anchor: const Offset(0.5, 0.5),
                zIndex: 15,
              ),
            );
            bIdx++;
          }
        } else {
          final displayCount = min(ct.territory.bombCount, 3);
          for (int i = 0; i < displayCount; i++) {
            final angle = (pi * 2 * i) / displayCount;
            final dist = max(diameterDeg * 0.15, 0.0001);
            final bLat = cLat + dist * sin(angle);
            final bLng = cLng + dist * cos(angle) / cosLat;
            markers.add(
              gmaps.Marker(
                markerId: gmaps.MarkerId('bomb_${id}_fb_$i'),
                position: gmaps.LatLng(bLat, bLng),
                icon: bombBmp,
                anchor: const Offset(0.5, 0.5),
                zIndex: 15,
              ),
            );
          }
        }
      }
    }

    // ── Battle zones: detect overlapping territories from different users ──
    final ids = smoothedMap.keys.toList();
    for (int i = 0; i < ids.length; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        final idA = ids[i];
        final idB = ids[j];
        final ctA = colored[idA]!;
        final ctB = colored[idB]!;
        if (ctA.territory.userId == ctB.territory.userId) continue;

        final ptsA = smoothedMap[idA]!;
        final ptsB = smoothedMap[idB]!;

        // Fast bounding-box rejection
        final bA = _getBounds(ptsA);
        final bB = _getBounds(ptsB);
        if (!bA.overlaps(bB)) continue;

        // Compute overlap polygon
        final overlapPts = _computeOverlapPolygon(ptsA, ptsB);
        if (overlapPts.length < 3) continue;

        // Battle zone fill
        polygons.add(
          gmaps.Polygon(
            polygonId: gmaps.PolygonId('battle_${idA}_$idB'),
            points: overlapPts,
            fillColor: const Color(0xFFFF6B00).withOpacity(0.35),
            strokeColor: const Color(0xFFFF6B00).withOpacity(0.75),
            strokeWidth: 2,
            zIndex: 5,
          ),
        );

        // Fight icon + "WAR ZONE" label at overlap center
        final center = _centroid(overlapPts);
        final warBmp = await _createWarZoneLabel();
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('fight_${idA}_$idB'),
            position: center,
            icon: warBmp,
            anchor: const Offset(0.5, 0.5),
            zIndex: 20,
          ),
        );
      }
    }

    // ── Place castle markers at territory centroids ──
    for (final ct in colored.values) {
      final id = ct.territory.id;
      if (!smoothedMap.containsKey(id)) continue;
      final proj = projMap[id]!;
      final cLat = proj.$1;
      final cLng = proj.$2;
      final isOwner = ct.territory.userId == currentUserId;

      final hull = hullCache[id]!;
      final diameterDeg = PolygonUtils.diameter(hull);

      if (diameterDeg > 0.00015) {
        final castleLabelBmp = await _createCastleWithLabel(
          ct.territory.username,
          ct.borderColor,
          isOwner,
        );
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('castle_$id'),
            position: gmaps.LatLng(cLat, cLng),
            icon: castleLabelBmp,
            anchor: const Offset(0.5, 0.5),
            zIndex: 10,
            onTap: onCastleTap != null ? () => onCastleTap(id) : null,
          ),
        );
      }
    }

    return KingdomNativeOverrides(polygons, markers);
  }

  // ── Geometry helpers ──

  static Rect _getBounds(List<gmaps.LatLng> pts) {
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return Rect.fromLTRB(minLng, minLat, maxLng, maxLat);
  }

  static gmaps.LatLng _centroid(List<gmaps.LatLng> pts) {
    double sLat = 0, sLng = 0;
    for (final p in pts) {
      sLat += p.latitude;
      sLng += p.longitude;
    }
    return gmaps.LatLng(sLat / pts.length, sLng / pts.length);
  }

  static List<gmaps.LatLng> _computeOverlapPolygon(
    List<gmaps.LatLng> polyA,
    List<gmaps.LatLng> polyB,
  ) {
    final overlapPts = <gmaps.LatLng>[];
    for (final p in polyA) {
      if (_pointInPolygon(p, polyB)) overlapPts.add(p);
    }
    for (final p in polyB) {
      if (_pointInPolygon(p, polyA)) overlapPts.add(p);
    }
    // Edge intersection points
    for (int i = 0; i < polyA.length; i++) {
      final a1 = polyA[i];
      final a2 = polyA[(i + 1) % polyA.length];
      for (int j = 0; j < polyB.length; j++) {
        final b1 = polyB[j];
        final b2 = polyB[(j + 1) % polyB.length];
        final ix = _segmentIntersection(a1, a2, b1, b2);
        if (ix != null) overlapPts.add(ix);
      }
    }
    if (overlapPts.length < 3) return overlapPts;

    // Sort by angle around centroid to form convex polygon
    double cLat = 0, cLng = 0;
    for (final p in overlapPts) {
      cLat += p.latitude;
      cLng += p.longitude;
    }
    cLat /= overlapPts.length;
    cLng /= overlapPts.length;
    overlapPts.sort((a, b) {
      return atan2(
        a.latitude - cLat,
        a.longitude - cLng,
      ).compareTo(atan2(b.latitude - cLat, b.longitude - cLng));
    });
    return overlapPts;
  }

  static bool _pointInPolygon(gmaps.LatLng pt, List<gmaps.LatLng> poly) {
    bool inside = false;
    int j = poly.length - 1;
    for (int i = 0; i < poly.length; i++) {
      final pi = poly[i];
      final pj = poly[j];
      if (((pi.latitude > pt.latitude) != (pj.latitude > pt.latitude)) &&
          (pt.longitude <
              (pj.longitude - pi.longitude) *
                      (pt.latitude - pi.latitude) /
                      (pj.latitude - pi.latitude) +
                  pi.longitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  static gmaps.LatLng? _segmentIntersection(
    gmaps.LatLng a1,
    gmaps.LatLng a2,
    gmaps.LatLng b1,
    gmaps.LatLng b2,
  ) {
    final d1x = a2.longitude - a1.longitude;
    final d1y = a2.latitude - a1.latitude;
    final d2x = b2.longitude - b1.longitude;
    final d2y = b2.latitude - b1.latitude;
    final denom = d1x * d2y - d1y * d2x;
    if (denom.abs() < 1e-12) return null;
    final t =
        ((b1.longitude - a1.longitude) * d2y -
            (b1.latitude - a1.latitude) * d2x) /
        denom;
    final u =
        ((b1.longitude - a1.longitude) * d1y -
            (b1.latitude - a1.latitude) * d1x) /
        denom;
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return gmaps.LatLng(a1.latitude + t * d1y, a1.longitude + t * d1x);
    }
    return null;
  }

  /// Darkens a colour by reducing its HSL lightness.
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
