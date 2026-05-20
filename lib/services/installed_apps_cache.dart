// lib/services/installed_apps_cache.dart

import 'dart:typed_data';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppsCache {
  InstalledAppsCache._();
  static final instance = InstalledAppsCache._();

  static const String _ownPackageName = 'com.example.notification_manager';

  List<CachedApp> _apps = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<CachedApp> get apps => _apps;

  /// Call once in main.dart init()
  Future<void> load() async {
    final installed = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );

    _apps =
        installed
            .where((a) => a.packageName != _ownPackageName)
            .map(
              (a) => CachedApp(
                packageName: a.packageName,
                appName: a.name,
                icon: a.icon,
              ),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
          );

    _loaded = true;
  }

  /// Force refresh (e.g. after app install/uninstall)
  Future<void> refresh() async {
    _loaded = false;
    await load();
  }
}

class CachedApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;

  const CachedApp({
    required this.packageName,
    required this.appName,
    this.icon,
  });
}
