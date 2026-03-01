import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/water_notification_service.dart';

class WaterProvider extends ChangeNotifier {
  static const _kGoalMl = 'water_goal_ml';
  static const _kServings = 'water_servings';
  static const _kStartHour = 'water_start_hour';
  static const _kStartMin = 'water_start_min';
  static const _kNotifEnabled = 'water_notif_enabled';
  static const _kConsumedToday = 'water_consumed_today';
  static const _kLastReset = 'water_last_reset';

  int _goalMl = 2500;
  int _servings = 8;
  int _startHour = 8;
  int _startMinute = 0;
  bool _notifEnabled = false;
  bool _isSetup = false;
  List<bool> _done = [];

  // ── Getters ─────────────────────────────────────────────────────────────────
  int get goalMl => _goalMl;
  int get servings => _servings;
  TimeOfDay get startTime => TimeOfDay(hour: _startHour, minute: _startMinute);
  bool get notifEnabled => _notifEnabled;
  bool get isSetup => _isSetup;
  List<bool> get done => List.unmodifiable(_done);

  int get servingMl => (_goalMl / _servings).round();
  int get consumedMl => _done.where((d) => d).length * servingMl;
  int get completedCount => _done.where((d) => d).length;
  double get progress =>
      _goalMl > 0 ? (consumedMl / _goalMl).clamp(0.0, 1.0) : 0.0;

  /// Time when the i-th serving should be drunk (spread across 16h from startTime).
  TimeOfDay getServingTime(int index) {
    const totalMinutes = 16 * 60;
    final interval = totalMinutes ~/ _servings;
    final startMins = _startHour * 60 + _startMinute;
    final mins = startMins + index * interval;
    return TimeOfDay(hour: (mins ~/ 60) % 24, minute: mins % 60);
  }

  // ── Load / Refresh ───────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isSetup = prefs.containsKey(_kGoalMl);
    _goalMl = prefs.getInt(_kGoalMl) ?? 2500;
    _servings = prefs.getInt(_kServings) ?? 8;
    _startHour = prefs.getInt(_kStartHour) ?? 8;
    _startMinute = prefs.getInt(_kStartMin) ?? 0;
    _notifEnabled = prefs.getBool(_kNotifEnabled) ?? false;
    _resetIfNewDay(prefs);
    notifyListeners();
  }

  /// Re-read from prefs (called when app resumes, after a notification tap).
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    notifyListeners();
  }

  void _resetIfNewDay(SharedPreferences prefs) {
    final today = _todayStr();
    if (prefs.getString(_kLastReset) != today) {
      _done = List.filled(_servings, false);
      prefs.setString(_kLastReset, today);
      prefs.setString(_kConsumedToday, json.encode(List.filled(_servings, 0)));
    } else {
      final raw = prefs.getString(_kConsumedToday);
      if (raw != null) {
        try {
          final list = json.decode(raw) as List;
          final bools = list.map((v) => v == true || v == 1).toList();
          _done = bools.length == _servings
              ? bools
              : List.filled(_servings, false);
        } catch (_) {
          _done = List.filled(_servings, false);
        }
      } else {
        _done = List.filled(_servings, false);
      }
    }
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Save Settings ────────────────────────────────────────────────────────────
  Future<void> saveSettings({
    required int goalMl,
    required int servings,
    required TimeOfDay startTime,
    required bool notifEnabled,
  }) async {
    _goalMl = goalMl;
    _servings = servings;
    _startHour = startTime.hour;
    _startMinute = startTime.minute;
    _notifEnabled = notifEnabled;
    _isSetup = true;
    _done = List.filled(_servings, false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGoalMl, _goalMl);
    await prefs.setInt(_kServings, _servings);
    await prefs.setInt(_kStartHour, _startHour);
    await prefs.setInt(_kStartMin, _startMinute);
    await prefs.setBool(_kNotifEnabled, _notifEnabled);
    await prefs.setString(
        _kConsumedToday, json.encode(List.filled(_servings, 0)));
    await prefs.setString(_kLastReset, _todayStr());

    if (_notifEnabled) {
      try {
        await WaterNotificationService.scheduleAll(
          servings: _servings,
          servingMl: servingMl,
          startTime: startTime,
        );
      } catch (_) {
        // Plugin not yet linked (needs full restart after first install) — ignore
      }
    } else {
      try {
        await WaterNotificationService.cancelAll();
      } catch (_) {}
    }
    notifyListeners();
  }

  // ── Mark Serving ─────────────────────────────────────────────────────────────
  Future<void> markServing(int index, bool value) async {
    if (index < 0 || index >= _done.length) return;
    _done = List.from(_done)..[index] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kConsumedToday, json.encode(_done.map((b) => b ? 1 : 0).toList()));
    notifyListeners();
  }

  Future<void> resetToday() async {
    _done = List.filled(_servings, false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kConsumedToday, json.encode(List.filled(_servings, 0)));
    await prefs.setString(_kLastReset, _todayStr());
    notifyListeners();
  }
}
