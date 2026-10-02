import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';

/// Shown on first launch (or whenever a required permission is missing).
/// The parent's WidgetsBindingObserver handles re-checking on app resume.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _nlEnabled = false;
  bool _overlayEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final ns = context.read<NotificationService>();
    final nl = await ns.isNotificationListenerEnabled();
    final ov = await ns.isOverlayPermissionGranted();
    if (mounted) setState(() { _nlEnabled = nl; _overlayEnabled = ov; });
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.read<NotificationService>();

    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // ── Logo + title ──
              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 68),
              const SizedBox(height: 20),
              const Text(
                'WA Filter',
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'See WhatsApp messages from selected contacts\nwithout ever opening WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),

              // ── Permission steps ──
              _PermissionStep(
                step: 1,
                title: 'Notification Access',
                description:
                    'Lets WA Filter read WhatsApp notifications in the background.',
                granted: _nlEnabled,
                onGrant: () async {
                  await ns.openNotificationSettings();
                  // User will enable in Settings; we re-check on resume
                },
              ),
              const SizedBox(height: 14),
              _PermissionStep(
                step: 2,
                title: 'Display Over Other Apps',
                description:
                    'Lets WA Filter show a floating panel over any screen.',
                granted: _overlayEnabled,
                onGrant: () async {
                  await ns.requestOverlayPermission();
                  await _check();
                },
              ),

              const Spacer(),

              // ── Continue button (only active when both are granted) ──
              AnimatedOpacity(
                opacity: (_nlEnabled && _overlayEnabled) ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // The HomeScreen WidgetsBindingObserver fires on resume
                    // and will transition to the main UI once both grants are confirmed.
                    onPressed: (_nlEnabled && _overlayEnabled) ? () {} : null,
                    child: const Text('Continue →'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onGrant;

  const _PermissionStep({
    required this.step,
    required this.title,
    required this.description,
    required this.granted,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: granted ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted ? const Color(0xFF25D366) : Colors.white30,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Step badge
          CircleAvatar(
            radius: 20,
            backgroundColor:
                granted ? const Color(0xFF25D366) : Colors.white24,
            child: granted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action
          if (!granted)
            TextButton(
              onPressed: onGrant,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Grant', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 28),
        ],
      ),
    );
  }
}
