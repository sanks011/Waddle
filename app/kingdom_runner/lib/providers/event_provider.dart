import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/event_room.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<EventRoom> _events = [];
  EventRoom? _currentEvent;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;
  Timer? _pollTimer;

  List<EventRoom> get events => _events;
  EventRoom? get currentEvent => _currentEvent;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;

  // ─── Events list ──────────────────────────────────────────────────────────

  Future<void> loadEvents({
    double? lat,
    double? lng,
    double radius = 10000,
    String search = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _api.getEvents(
        lat: lat,
        lng: lng,
        radius: radius,
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create event ─────────────────────────────────────────────────────────

  Future<EventRoom?> createEvent({
    required String title,
    String description = '',
    required double lat,
    required double lng,
    required bool isPublic,
    String? password,
  }) async {
    try {
      final created = await _api.createEvent(
        title: title,
        description: description,
        lat: lat,
        lng: lng,
        isPublic: isPublic,
        password: password,
      );
      _events.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── Join event ───────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string on failure.
  Future<String?> joinEvent(String eventId, {String? password}) async {
    try {
      final updated = await _api.joinEvent(eventId, password: password);
      _currentEvent = updated;
      // Also patch it in the list if present
      final idx = _events.indexWhere((e) => e.id == eventId);
      if (idx >= 0) _events[idx] = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ─── Delete event ─────────────────────────────────────────────────────────

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _api.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      if (_currentEvent?.id == eventId) {
        _currentEvent = null;
        _messages = [];
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Current event / chat ────────────────────────────────────────────────

  Future<void> openEvent(EventRoom room) async {
    _currentEvent = room;
    _messages = [];
    notifyListeners();
    await loadMessages(room.id);
    _startPolling(room.id);
  }

  void closeEvent() {
    _pollTimer?.cancel();
    _currentEvent = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> loadMessages(String eventId, {String? before}) async {
    try {
      final fetched = await _api.getMessages(eventId, before: before);
      if (before == null) {
        _messages = fetched;
      } else {
        // Prepend older messages (pagination)
        _messages = [...fetched, ..._messages];
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> sendMessage(String eventId, String content) async {
    if (content.trim().isEmpty) return false;
    _isSendingMessage = true;
    notifyListeners();

    try {
      final msg = await _api.sendMessage(eventId, content.trim());
      _messages.add(msg);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // ─── Polling ──────────────────────────────────────────────────────────────

  void _startPolling(String eventId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_currentEvent?.id != eventId) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final fetched = await _api.getMessages(eventId);
        if (fetched.length != _messages.length ||
            (fetched.isNotEmpty &&
                _messages.isNotEmpty &&
                fetched.last.id != _messages.last.id)) {
          _messages = fetched;
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
