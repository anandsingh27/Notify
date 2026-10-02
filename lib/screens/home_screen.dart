import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/filter_service.dart';
import '../services/notification_service.dart';
import 'filters_tab.dart';
import 'messages_tab.dart';
import 'permissions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;
  bool _ready = false;      // true once both permissions are granted
  bool _checking = true;    // shows a spinner on first check

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-checks every time the user returns from the Settings screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final ns = context.read<NotificationService>();
    final nlOk  = await ns.isNotificationListenerEnabled();
    final ovOk  = await ns.isOverlayPermissionGranted();
    final ready = nlOk && ovOk;

    if (ready && !_ready) {
      // First time both grants land: wire up services and start the stream
      ns.attach(context.read<FilterService>());
      ns.startListening();
    }
    if (mounted) setState(() { _ready = ready; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF075E54),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_ready) return const PermissionsScreen();

    return Consumer2<NotificationService, FilterService>(
      builder: (_, ns, fs, __) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF075E54),
          elevation: 0,
          title: const Text(
            'WA Filter',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Clear all messages button (only on Messages tab)
            if (_tab == 0 && ns.messages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                tooltip: 'Clear history',
                onPressed: () => _confirmClear(ns),
              ),
            // Unread badge
            if (ns.unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ns.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: const [MessagesTab(), FiltersTab()],
        ),
        floatingActionButton: _tab == 1
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                tooltip: 'Add contact / group',
                onPressed: () => FiltersTab.showAddDialog(context),
                child: const Icon(Icons.person_add_rounded),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          selectedItemColor: const Color(0xFF075E54),
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _tab = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: const Icon(Icons.chat_bubble_rounded),
              label: 'Messages${ns.unreadCount > 0 ? " (${ns.unreadCount})" : ""}',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.filter_alt_outlined),
              activeIcon: Icon(Icons.filter_alt_rounded),
              label: 'Filters',
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(NotificationService ns) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Delete all saved messages?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ns.clearMessages();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
