import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Runs in a **separate Flutter isolate** spawned by flutter_overlay_window.
/// Receives data via [FlutterOverlayWindow.overlayListener].
///
/// Two states:
///   • expanded  — a compact card panel (up to 5 messages)
///   • bubble    — a small draggable circle with unread badge
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget>
    with SingleTickerProviderStateMixin {
  static const _green     = Color(0xFF25D366);
  static const _darkGreen = Color(0xFF075E54);
  static const _maxShown  = 30;

  final List<Map<String, dynamic>> _msgs = [];
  bool _expanded = true;

  static const _avatarColors = [
    Color(0xFF1ABC9C), Color(0xFF2ECC71), Color(0xFF3498DB),
    Color(0xFF9B59B6), Color(0xFFE67E22), Color(0xFFE74C3C),
    Color(0xFF16A085), Color(0xFF8E44AD),
  ];

  @override
  void initState() {
    super.initState();
    // Receive messages sent from the main-app isolate via shareData()
    FlutterOverlayWindow.overlayListener.listen((raw) {
      if (raw == null || !mounted) return;
      try {
        final data = jsonDecode(raw.toString()) as Map<String, dynamic>;
        setState(() {
          _msgs.insert(0, data);
          if (_msgs.length > _maxShown) _msgs.removeLast();
          _expanded = true; // pop open on new message
        });
      } catch (_) {}
    });
  }

  Color _colorFor(String s) =>
      _avatarColors[s.isEmpty ? 0 : s.codeUnitAt(0) % _avatarColors.length];

  String _timeLabel(dynamic ms) {
    if (ms == null) return '';
    final diff = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ms as int));
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _expanded ? _panel() : _bubble(),
      ),
    );
  }

  // ── Bubble (collapsed) ─────────────────────────────────────────────────────

  Widget _bubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 10,
                  spreadRadius: 1)
            ],
          ),
          child: Stack(
            children: [
              const Center(
                  child: Icon(Icons.chat_bubble_rounded,
                      color: Colors.white, size: 28)),
              if (_msgs.isNotEmpty)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      _msgs.length > 9 ? '9+' : '${_msgs.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Panel (expanded) ───────────────────────────────────────────────────────

  Widget _panel() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 315,
        constraints: const BoxConstraints(maxHeight: 490),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 28,
                spreadRadius: 2)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              _msgs.isEmpty ? _empty() : _list(),
              if (_msgs.isNotEmpty) _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      color: _darkGreen,
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('WA Filter',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          if (_msgs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('${_msgs.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],
          // Minimise
          _iconBtn(Icons.minimize_rounded,
              () => setState(() => _expanded = false)),
          // Close overlay entirely
          _iconBtn(Icons.close_rounded,
              () => FlutterOverlayWindow.closeOverlay()),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      );

  Widget _empty() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded, size: 38, color: Colors.grey),
            SizedBox(height: 8),
            Text('Waiting for messages…',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );

  Widget _list() => Flexible(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: _msgs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 0, indent: 58, thickness: 0.5),
          itemBuilder: (_, i) {
            final m      = _msgs[i];
            final sender = (m['sender'] as String?) ?? '';
            final text   = (m['text']   as String?) ?? '';
            return ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              leading: CircleAvatar(
                radius: 19,
                backgroundColor: _colorFor(sender),
                child: Text(
                  sender.isEmpty ? '?' : sender[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              title: Text(sender,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
              trailing: Text(_timeLabel(m['time']),
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            );
          },
        ),
      );

  Widget _footer() => GestureDetector(
        onTap: () => setState(() => _msgs.clear()),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
          child: const Center(
            child: Text('Clear',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}
