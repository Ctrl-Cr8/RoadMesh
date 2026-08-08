// ─── RoadMesh Mobile Application ─────────────────────────────────────────────
//
// Cooperative Vehicle Awareness Platform
// Entry point with Provider setup and premium Material 3 dark theme.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/driving_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Full-immersion dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepSpace,
      systemNavigationBarIconBrightness: Brightness.light,
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
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
