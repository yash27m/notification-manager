import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/database/pref_service.dart';
import 'package:notification_manager/screens/home/dashboard/dashboard_screen.dart';
import 'package:notification_manager/screens/onboarding/welcome/welcome.dart';
import 'package:notification_manager/database/notification_db.dart';
import 'package:notification_manager/services/installed_apps_cache.dart';
import 'package:notification_manager/services/notification_engine.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NotificationApp());
}

Future<void> init() async {
  await Hive.initFlutter();
  await HiveService.instance.init();
  await NotificationDB.instance.init();
  await PrefService.instance.init();
  NotificationEngine.instance.init();
  await InstalledAppsCache.instance.load();
}

class NotificationApp extends StatefulWidget {
  const NotificationApp({super.key});

  @override
  State<NotificationApp> createState() => _NotificationAppState();
}

class _NotificationAppState extends State<NotificationApp> {
  static const _primaryPink = Color(0xFF2AAEA1);

  @override
  void initState() {
    super.initState();
    // Remove splash screen after app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _primaryPink,
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: PrefService.instance.isOnboardingDone
          ? const DashboardScreen()
          : const WelcomeScreen(),
    );
  }
}
