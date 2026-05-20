import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/screens/onboarding/permissions/permission.dart';
import 'package:notification_manager/services/installed_apps_cache.dart';

class ChooseAppsController {
  // ── State ──

  final isLoading = ValueNotifier<bool>(true);
  final allApps = ValueNotifier<List<AppItem>>([]);
  final filteredApps = ValueNotifier<List<AppItem>>([]);
  final selectedCount = ValueNotifier<int>(0);
  final searchController = TextEditingController();

  // ── WhatsApp folder access state ──

  final whatsappAccessList = ValueNotifier<List<WhatsAppAccess>>([]);

  static const _channel = MethodChannel(
    'com.example.notification_manager/permissions',
  );

  // ── Default trending apps (selected + pinned on top) ──

  static const defaultSelectedPackages = <String>{
    // WhatsApp
    'com.whatsapp',
    'com.whatsapp.w4b',
    // Messaging
    'org.telegram.messenger',
    'com.facebook.orca',
    'com.Slack',
    'com.discord',
    'com.viber.voip',
    'com.google.android.apps.messaging',
    // Social Media
    'com.instagram.android',
    'com.snapchat.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.twitter.android',
    'com.facebook.katana',
    'com.linkedin.android',
    'com.pinterest',
    'com.reddit.frontpage',
    'com.google.android.youtube',
  };

  static const _whatsappPackages = <String>{'com.whatsapp', 'com.whatsapp.w4b'};

  static const _whatsappLabels = <String, String>{
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
  };

  // ── Init ──

  Future<void> init() async {
    isLoading.value = true;

    final installed = InstalledAppsCache.instance.apps;

    final items = installed.map((app) {
      final isDefault = defaultSelectedPackages.contains(app.packageName);
      return AppItem(
        packageName: app.packageName,
        appName: app.appName,
        icon: app.icon,
        isSelected: isDefault,
        isWhatsApp: _whatsappPackages.contains(app.packageName),
        isDefaultApp: isDefault,
      );
    }).toList();

    items.sort(_appSorter);

    allApps.value = items;
    filteredApps.value = List.from(items);
    _updateCount();
    await _refreshWhatsAppAccess();

    isLoading.value = false;
    searchController.addListener(_onSearch);
  }

  // ── Sort ──

  int _appSorter(AppItem a, AppItem b) {
    if (a.isWhatsApp && !b.isWhatsApp) return -1;
    if (!a.isWhatsApp && b.isWhatsApp) return 1;
    if (a.isDefaultApp && !b.isDefaultApp) return -1;
    if (!a.isDefaultApp && b.isDefaultApp) return 1;
    return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
  }

  // ── Toggle ──

  void toggleApp(int index) {
    final list = filteredApps.value;
    list[index].isSelected = !list[index].isSelected;
    filteredApps.value = List.from(list);
    _updateCount();
    _refreshWhatsAppAccess();
  }

  void toggleAll() {
    final allSelected = selectedCount.value == allApps.value.length;
    for (final app in allApps.value) {
      app.isSelected = !allSelected;
    }
    filteredApps.value = List.from(filteredApps.value);
    _updateCount();
    _refreshWhatsAppAccess();
  }

  bool get isAllSelected =>
      selectedCount.value == allApps.value.length && allApps.value.isNotEmpty;

  // ── Search ──

  void _onSearch() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredApps.value = List.from(allApps.value);
    } else {
      filteredApps.value = allApps.value
          .where((app) => app.appName.toLowerCase().contains(query))
          .toList();
    }
  }

  // ── Count ──

  void _updateCount() {
    selectedCount.value = allApps.value.where((a) => a.isSelected).length;
  }

  // ── WhatsApp folder access ──

  Future<void> _refreshWhatsAppAccess() async {
    final selectedWA = allApps.value
        .where((a) => a.isSelected && a.isWhatsApp)
        .toList();

    if (selectedWA.isEmpty) {
      whatsappAccessList.value = [];
      return;
    }

    final list = <WhatsAppAccess>[];
    for (final app in selectedWA) {
      final hasAccess = await _hasWhatsAppFolderAccess(app.packageName);
      list.add(
        WhatsAppAccess(
          packageName: app.packageName,
          displayName: _whatsappLabels[app.packageName] ?? app.appName,
          icon: app.icon,
          hasAccess: hasAccess,
        ),
      );
    }
    whatsappAccessList.value = list;
  }

  Future<bool> _hasWhatsAppFolderAccess(String packageName) async {
    try {
      return await _channel.invokeMethod<bool>('hasWhatsAppFolderAccess', {
            'packageName': packageName,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestWhatsAppAccess(String packageName) async {
    try {
      await _channel.invokeMethod('requestWhatsAppFolderAccess', {
        'packageName': packageName,
      });
      // Result comes back on resume
    } catch (_) {}
  }

  /// Called on app resume to recheck SAF permissions
  Future<void> onResume() async {
    await _refreshWhatsAppAccess();
  }

  // ── Confirm ──

  Future<void> confirmSelection(BuildContext context) async {
    final selected = allApps.value.where((a) => a.isSelected).toList();

    final models = selected
        .map(
          (a) => SelectedAppModel(
            packageName: a.packageName,
            appName: a.appName,
            icon: a.icon,
          ),
        )
        .toList();

    await HiveService.instance.saveSelectedApps(models);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionScreen()),
      );
    }
  }

  // ── Dispose ──

  void dispose() {
    searchController.dispose();
    isLoading.dispose();
    allApps.dispose();
    filteredApps.dispose();
    selectedCount.dispose();
    whatsappAccessList.dispose();
  }
}

// ── Models ───────────────────────────────────────────────────────────────────

class AppItem {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  bool isSelected;
  final bool isWhatsApp;
  final bool isDefaultApp;

  AppItem({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isSelected = false,
    this.isWhatsApp = false,
    this.isDefaultApp = false,
  });
}

class WhatsAppAccess {
  final String packageName;
  final String displayName;
  final Uint8List? icon;
  final bool hasAccess;

  const WhatsAppAccess({
    required this.packageName,
    required this.displayName,
    this.icon,
    this.hasAccess = false,
  });
}
