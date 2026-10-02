import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/filter_service.dart';
import 'services/notification_service.dart';
import 'widgets/overlay_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY ENTRY POINT
// flutter_overlay_window spawns a second Flutter isolate that calls this.
// It must be a top-level function annotated with @pragma("vm:entry-point").
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN APP ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilterService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const WaFilterApp(),
    ),
  );
}

class WaFilterApp extends StatelessWidget {
  const WaFilterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WA Filter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF25D366),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF075E54),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF25D366),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
