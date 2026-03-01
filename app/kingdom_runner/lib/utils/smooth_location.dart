import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';

/// Pokemon-Go-style smooth location tracker.
///
/// GPS ───► Kalman filter ───► spike rejection ───► animated lerp ───► output
///
/// The [onSmoothedLocation] callback fires ~60 fps with the interpolated
/// position so the map marker glides instead of jumping.
class SmoothLocationProvider {
  SmoothLocationProvider({this.onSmoothedLocation});

  /// Called at display-refresh rate with the smoothed position.
  void Function(LatLng position)? onSmoothedLocation;

  // ── Kalman state (lat & lng are independent 1-D filters) ──
  double? _kLat, _kLng; // current Kalman estimate
  double _pLat = 1.0, _pLng = 1.0; // estimate covariance
  /// Process noise – how much we expect the user to move per update.
  /// Smaller = smoother but slower to react.  Tuned for walking.
  static const double _q = 0.00000003; // ~3 m² in degrees²
  /// Base measurement noise – overridden per-reading if accuracy is available.
  static const double _rBase = 0.000001; // ~10 m² in degrees²

  // ── Spike rejection ──
  LatLng? _lastAccepted;
  DateTime? _lastAcceptedTime;
  static const double _maxJumpMeters = 60.0; // reject > 60 m jumps
  static const double _maxSpeedMps = 14.0; // ~50 km/h

  // ── Animation (lerp) state ──
  LatLng? _animStart;
  LatLng? _animEnd;
  double _animT = 1.0; // 0..1   (1 = arrived)
  /// Duration of the position interpolation.  Slightly longer than the
  /// expected GPS interval (~1 s for bestForNavigation @ 3 m filter)
  /// so the marker never "waits" at the destination.
  static const Duration _animDuration = Duration(milliseconds: 900);
  Ticker? _ticker;
  int _animStartMs = 0;

  /// The latest smoothed position (available synchronously).
  LatLng? get currentPosition =>
      _animEnd ?? (_kLat != null ? LatLng(_kLat!, _kLng!) : null);

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Feed a raw GPS reading.  [accuracyMeters] is the horizontal accuracy
  /// reported by the platform (used to scale the Kalman R value).
  void updateRawPosition(LatLng raw, {double accuracyMeters = 10.0}) {
    // 1. Spike rejection
    if (_lastAccepted != null && _lastAcceptedTime != null) {
      final dist = _haversineMeters(_lastAccepted!, raw);
      final elapsed =
          DateTime.now().difference(_lastAcceptedTime!).inMilliseconds / 1000.0;
      if (dist > _maxJumpMeters) return; // hard cap
      if (elapsed > 0 && (dist / elapsed) > _maxSpeedMps) return; // speed cap
    }
    _lastAccepted = raw;
    _lastAcceptedTime = DateTime.now();

    // 2. Kalman filter (independently for lat & lng)
    // Measurement noise proportional to reported accuracy
    final r = max(
      _rBase,
      (accuracyMeters / 111320.0) * (accuracyMeters / 111320.0),
    );

    if (_kLat == null) {
      // First reading – initialise
      _kLat = raw.latitude;
      _kLng = raw.longitude;
      _pLat = r;
      _pLng = r;
    } else {
      // Predict
      _pLat += _q;
      _pLng += _q;
      // Update
      final kGainLat = _pLat / (_pLat + r);
      final kGainLng = _pLng / (_pLng + r);
      _kLat = _kLat! + kGainLat * (raw.latitude - _kLat!);
      _kLng = _kLng! + kGainLng * (raw.longitude - _kLng!);
      _pLat = (1 - kGainLat) * _pLat;
      _pLng = (1 - kGainLng) * _pLng;
    }

    final filtered = LatLng(_kLat!, _kLng!);

    // 3. Start animation towards the filtered position
    _animStart = _animEnd ?? filtered;
    _animEnd = filtered;
    _animT = 0.0;
    _animStartMs = DateTime.now().millisecondsSinceEpoch;

    // Ensure the ticker is running
    _ensureTicker();
  }

  /// Attach to a [TickerProvider] (the State that mixes in
  /// TickerProviderStateMixin). Call once in `initState`.
  void attachTicker(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker(_onTick);
    // Don't start yet – will start on first GPS update.
  }

  /// Release resources.  Call from `dispose()`.
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }

  /// Hard-reset the filter (e.g. on re-center).
  void reset() {
    _kLat = null;
    _kLng = null;
    _pLat = 1.0;
    _pLng = 1.0;
    _lastAccepted = null;
    _lastAcceptedTime = null;
    _animStart = null;
    _animEnd = null;
    _animT = 1.0;
  }

  /// Immediately jump to a position (e.g. initial GPS fix) without animation.
  void jumpTo(LatLng pos) {
    _kLat = pos.latitude;
    _kLng = pos.longitude;
    _pLat = _rBase;
    _pLng = _rBase;
    _lastAccepted = pos;
    _lastAcceptedTime = DateTime.now();
    _animStart = pos;
    _animEnd = pos;
    _animT = 1.0;
    onSmoothedLocation?.call(pos);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────────────────

  void _ensureTicker() {
    if (_ticker == null) return;
    if (!_ticker!.isActive) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_animStart == null || _animEnd == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final progress =
        (now - _animStartMs) / _animDuration.inMilliseconds.toDouble();
    _animT = progress.clamp(0.0, 1.0);

    // Ease-out cubic for natural deceleration
    final t = 1.0 - pow(1.0 - _animT, 3).toDouble();

    final lat =
        _animStart!.latitude + (_animEnd!.latitude - _animStart!.latitude) * t;
    final lng =
        _animStart!.longitude +
        (_animEnd!.longitude - _animStart!.longitude) * t;

    onSmoothedLocation?.call(LatLng(lat, lng));

    // Stop the ticker when animation is complete AND no new target pending
    if (_animT >= 1.0) {
      _ticker?.stop();
    }
  }

  /// Haversine distance in metres (fast approx is fine for short distances).
  static double _haversineMeters(LatLng a, LatLng b) {
    const R = 6371000.0; // Earth radius in metres
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final h =
        sinDLat * sinDLat +
        cos(_deg2rad(a.latitude)) *
            cos(_deg2rad(b.latitude)) *
            sinDLng *
            sinDLng;
    return R * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _deg2rad(double deg) => deg * pi / 180.0;
}
