import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the whitelist of WhatsApp contact/group names.
///
/// The match is exact case-insensitive on the notification title
/// (which equals the sender name for 1-to-1 chats, or the group name
/// for group chats on modern WhatsApp versions).
///
/// Empty whitelist = show ALL messages (no filtering).
class FilterService extends ChangeNotifier {
  static const _prefsKey = 'wafilter_whitelist';

  List<String> _filters = [];

  List<String> get filters => List.unmodifiable(_filters);

  /// True when the whitelist is empty and every message is allowed.
  bool get showAll => _filters.isEmpty;

  FilterService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _filters = prefs.getStringList(_prefsKey) ?? [];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _filters);
  }

  /// Returns true if [sender] is allowed through the filter.
  bool passes(String sender) {
    if (_filters.isEmpty) return true;
    return _filters.any((f) => f.toLowerCase() == sender.toLowerCase());
  }

  Future<void> addFilter(String name) async {
    name = name.trim();
    if (name.isEmpty) return;
    if (_filters.any((f) => f.toLowerCase() == name.toLowerCase())) return;
    _filters.add(name);
    await _save();
    notifyListeners();
  }

  Future<void> removeFilter(String name) async {
    _filters.removeWhere((f) => f.toLowerCase() == name.toLowerCase());
    await _save();
    notifyListeners();
  }
}
