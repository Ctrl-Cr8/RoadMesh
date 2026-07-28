// ─── RoadMesh Mobile Application ────────────────────────────────────────────
//
// Cooperative Vehicle Awareness Platform
// Entry point with Provider setup and Material dark theme.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/driving_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUIOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RoadMeshApp());
}

class RoadMeshApp extends StatelessWidget {
  const RoadMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrivingProvider()),
      ],
      child: MaterialApp(
        title: 'RoadMesh',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0E1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00E5FF),
            secondary: Color(0xFF2979FF),
            surface: Color(0xFF121828),
            error: Color(0xFFF44336),
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A0E1A),
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
