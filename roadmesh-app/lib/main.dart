// ─── RoadMesh Mobile Application ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/driving_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'services/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepSpace,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  AppLogger.info('RoadMesh starting — onboarding complete: $onboardingComplete');

  runApp(RoadMeshApp(showOnboarding: !onboardingComplete));
}

class RoadMeshApp extends StatelessWidget {
  final bool showOnboarding;

  const RoadMeshApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrivingProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: MaterialApp(
        title: 'RoadMesh',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: showOnboarding
            ? OnboardingScreen(
                onComplete: () => AppLogger.info('Onboarding complete'),
              )
            : const HomeScreen(),
      ),
    );
  }
}
