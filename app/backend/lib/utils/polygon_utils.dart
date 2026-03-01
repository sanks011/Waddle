import 'dart:math';
import 'dart:ui';

/// Geometry utilities used by the kingdom territory layer.
class PolygonUtils {
  // ─── Convex Hull (Graham Scan) ────────────────────────────────────────────

  /// Computes the convex hull of [points] using Graham scan.
  /// Returns the hull in counter-clockwise order.
  /// This is the core step that turns a messy GPS path into a clean island.
  static List<Offset> convexHull(List<Offset> points) {
    if (points.length < 3) return points;

    // Find the bottom-most (then left-most) point as the pivot
    Offset pivot = points.reduce(
      (a, b) => (a.dy > b.dy || (a.dy == b.dy && a.dx < b.dx)) ? a : b,
    );

    // Sort by polar angle relative to pivot
    final sorted = List<Offset>.from(points)
      ..sort((a, b) {
        if (a == pivot) return -1;
        if (b == pivot) return 1;
        final angleA = atan2(a.dy - pivot.dy, a.dx - pivot.dx);
        final angleB = atan2(b.dy - pivot.dy, b.dx - pivot.dx);
        if (angleA != angleB) return angleA.compareTo(angleB);
        // Same angle → keep the closer point first
        final dA = (a - pivot).distanceSquared;
        final dB = (b - pivot).distanceSquared;
        return dA.compareTo(dB);
      });

    // Graham scan
    final hull = <Offset>[];
    for (final p in sorted) {
      while (hull.length >= 2 &&
          _cross(hull[hull.length - 2], hull[hull.length - 1], p) <= 0) {
        hull.removeLast();
      }
      hull.add(p);
    }
    return hull;
  }

  static double _cross(Offset O, Offset A, Offset B) =>
      (A.dx - O.dx) * (B.dy - O.dy) - (A.dy - O.dy) * (B.dx - O.dx);

  // ─── Catmull-Rom spline smoothing ─────────────────────────────────────────

  /// Returns a smooth closed polygon by running Catmull-Rom spline subdivision
  /// on [points].  [subdivisions] controls how many extra points are inserted
  /// per segment (higher = smoother, heavier).
  static List<Offset> smoothPolygon(
    List<Offset> points, {
    int subdivisions = 14,
  }) {
    if (points.length < 3) return points;
    final n = points.length;
    final result = <Offset>[];
    for (int i = 0; i < n; i++) {
      final p0 = points[(i - 1 + n) % n];
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final p3 = points[(i + 2) % n];
      for (int j = 0; j < subdivisions; j++) {
        result.add(_catmullRom(p0, p1, p2, p3, j / subdivisions));
      }
    }
    return result;
  }

  static Offset _catmullRom(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    return Offset(
      0.5 *
          ((2 * p1.dx) +
              (-p0.dx + p2.dx) * t +
              (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
              (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3),
      0.5 *
          ((2 * p1.dy) +
              (-p0.dy + p2.dy) * t +
              (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
              (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3),
    );
  }

  // ─── Polygon centroid ──────────────────────────────────────────────────────

  /// Returns the geometric centroid of a polygon given as screen [Offset]s.
  static Offset centroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    if (points.length == 2) {
      return Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );
    }
    double cx = 0, cy = 0, area = 0;
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final cross = points[i].dx * points[j].dy - points[j].dx * points[i].dy;
      area += cross;
      cx += (points[i].dx + points[j].dx) * cross;
      cy += (points[i].dy + points[j].dy) * cross;
    }
    area /= 2;
    if (area.abs() < 0.001) {
      // Fallback: simple average
      double ax = 0, ay = 0;
      for (final p in points) {
        ax += p.dx;
        ay += p.dy;
      }
      return Offset(ax / n, ay / n);
    }
    return Offset(cx / (6 * area), cy / (6 * area));
  }

  // ─── Point-in-polygon ─────────────────────────────────────────────────────

  /// Ray-casting test: returns true if [point] is inside [polygon].
  static bool containsPoint(List<Offset> polygon, Offset point) {
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

  // ─── Doodlish perturbation ────────────────────────────────────────────────

  /// Perturbs each point by a tiny seeded-random amount to give a hand-drawn
  /// sketchy / doodlish appearance.  The seed keeps perturbations stable
  /// across redraws.
  static List<Offset> doodlize(
    List<Offset> points,
    int seed, {
    double amount = 1.8,
  }) {
    final rng = Random(seed);
    return points
        .map(
          (p) => Offset(
            p.dx + (rng.nextDouble() - 0.5) * amount * 2,
            p.dy + (rng.nextDouble() - 0.5) * amount * 2,
          ),
        )
        .toList();
  }

  // ─── Path builder ─────────────────────────────────────────────────────────

  /// Converts a list of [Offset]s to a closed [Path] using straight lines.
  static Path toPath(List<Offset> points) {
    if (points.isEmpty) return Path();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  /// Builds a smooth closed [Path] using cubic Bézier curves through [points].
  /// Each segment uses mid-points as anchors so the curve always passes through
  /// all original points — giving a genuinely rounded island silhouette.
  static Path toBezierPath(List<Offset> points) {
    if (points.length < 3) return toPath(points);
    final n = points.length;
    final path = Path();

    // Start at the midpoint between last and first point
    final start = _mid(points[n - 1], points[0]);
    path.moveTo(start.dx, start.dy);

    for (int i = 0; i < n; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final mid = _mid(p1, p2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  static Offset _mid(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  // ─── Approximate screen diameter ──────────────────────────────────────────

  /// Returns the approximate diameter (max extent) of the polygon in pixels.
  static double diameter(List<Offset> points) {
    if (points.length < 2) return 0;
    double maxD = 0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d > maxD) maxD = d;
      }
    }
    return maxD;
  }
}
