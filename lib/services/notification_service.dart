import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wa_message.dart';
import 'filter_service.dart';

/// Bridges the Kotlin EventChannel, applies the filter, persists messages,
/// and drives the floating overlay window.
class NotificationService extends ChangeNotifier {
  // ── Channel names (must match MainActivity.kt) ──────────────────────────
  static const _notifChannel = EventChannel('wafilter/notifications');
  static const _controlChannel = MethodChannel('wafilter/control');

  // ── Storage key for message history ─────────────────────────────────────
  static const _msgsKey = 'wafilter_messages';
  static const _maxMessages = 60;

  StreamSubscription<dynamic>? _sub;
  List<WaMessage> _messages = [];
  int _unreadCount = 0;
  FilterService? _filterService;

  // ── Public state ─────────────────────────────────────────────────────────
  List<WaMessage> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;

  NotificationService() {
    _loadMessages();
  }

  /// Must be called once after both services are created (see HomeScreen).
  void attach(FilterService fs) => _filterService = fs;

  // ── Listening ─────────────────────────────────────────────────────────────

  void startListening() {
    _sub ??= _notifChannel
        .receiveBroadcastStream()
        .listen(_onRaw, onError: (_) {});
  }

  void _onRaw(dynamic event) async {
    if (event == null) return;
    final data = Map<String, dynamic>.from(event as Map);

    final sender = (data['title'] as String? ?? '').trim();
    final text   = (data['text']  as String? ?? '').trim();
    final timeMs = data['time'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    if (sender.isEmpty || text.isEmpty) return;
    if (_filterService != null && !_filterService!.passes(sender)) return;

    final msg = WaMessage(
      sender: sender,
      text: text,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(timeMs),
    );

    _messages.insert(0, msg);
    if (_messages.length > _maxMessages) _messages.removeLast();
    _unreadCount++;
    _saveMessages(); // fire-and-forget
    notifyListeners();

    await _pushToOverlay(msg);
  }

  // ── Overlay communication ─────────────────────────────────────────────────

  Future<void> _pushToOverlay(WaMessage msg) async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        await FlutterOverlayWindow.showOverlay(
          height: 520,
          width: 330,
          alignment: OverlayAlignment.center,
          overlayTitle: 'WA Filter',
          overlayContent: '${msg.sender}: ${msg.text}',
          flag: OverlayFlag.defaultFlag,
          enableDrag: true,
          positionGravity: PositionGravity.auto,
        );
        // Give the overlay isolate time to initialise its listener
        await Future.delayed(const Duration(milliseconds: 350));
      }
      await FlutterOverlayWindow.shareData(jsonEncode({
        'sender': msg.sender,
        'text': msg.text,
        'time': msg.receivedAt.millisecondsSinceEpoch,
      }));
    } catch (_) {
      // Overlay permission not granted or service not ready – silently ignore
    }
  }

  // ── Message history CRUD ──────────────────────────────────────────────────

  Future<void> markAllRead() async {
    for (final m in _messages) {
      m.isRead = true;
    }
    _unreadCount = 0;
    await _saveMessages();
    notifyListeners();
  }

  Future<void> clearMessages() async {
    _messages.clear();
    _unreadCount = 0;
    await _saveMessages();
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_msgsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _messages = list
          .map((e) => WaMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = _messages.where((m) => !m.isRead).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _msgsKey,
      jsonEncode(_messages.map((m) => m.toJson()).toList()),
    );
  }

  // ── Permission helpers (called from UI) ────────────────────────────────────

  Future<bool> isNotificationListenerEnabled() async {
    try {
      return await _controlChannel
              .invokeMethod<bool>('isNotificationListenerEnabled') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _controlChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  Future<bool> isOverlayPermissionGranted() async =>
      FlutterOverlayWindow.isPermissionGranted();

  Future<void> requestOverlayPermission() async =>
      FlutterOverlayWindow.requestPermission();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
