import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_manager/database/pref_service.dart';
import 'package:notification_manager/screens/home/dashboard/dashboard_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionController {
  // ── State ──

  final permissions = ValueNotifier<List<PermissionItem>>([]);
  final allGranted = ValueNotifier<bool>(false);

  bool _autostartVisited = false;

  // ── Platform channel ──

  static const _channel = MethodChannel(
    'com.example.notification_manager/permissions',
  );

  // ── Init ──

  Future<void> init() async {
    final items = <PermissionItem>[];

    // 1. Background autostart — only on supported OEMs
    // final autostartAvailable = await _isAutostartAvailable();

    // if (autostartAvailable) {
    //   items.add(
    //     PermissionItem(
    //       type: PermissionType.autostart,
    //       title: 'Background autostart',
    //       description:
    //           'Auto Start permission is needed in your phone to allow the app to start in the background.',
    //       icon: Icons.flash_on_rounded,
    //     ),
    //   );
    // }

    // 2. Notification access (NotificationListenerService)
    items.add(
      PermissionItem(
        type: PermissionType.notificationAccess,
        title: 'Notification access',
        description:
            'Read, backup, and recover messages through your notifications, automatically.',
        icon: Icons.notifications_rounded,
      ),
    );

    // 3. Notifications (POST_NOTIFICATIONS — system dialog)
    items.add(
      PermissionItem(
        type: PermissionType.notifications,
        title: 'Notifications',
        description:
            'Allow the app to send you notifications about backed up messages and important updates.',
        icon: Icons.circle_notifications_rounded,
      ),
    );

    permissions.value = items;
    await _checkAllStatuses();
  }

  // ── Native checks ──

  // Future<bool> _isAutostartAvailable() async {
  //   try {
  //     return await _channel.invokeMethod<bool>('isAutostartAvailable') ?? false;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  Future<bool> _isNotificationListenerEnabled() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isNotificationListenerEnabled',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  // ── Check all statuses ──

  Future<void> _checkAllStatuses() async {
    final items = permissions.value;

    for (final item in items) {
      item.status = await _checkStatus(item);
    }

    permissions.value = List.from(items);
    _updateAllGranted();
  }

  Future<PermissionState> _checkStatus(PermissionItem item) async {
    switch (item.type) {
      case PermissionType.autostart:
        // No API to verify — granted after user visits settings & returns
        return _autostartVisited
            ? PermissionState.granted
            : PermissionState.notRequested;

      case PermissionType.notificationAccess:
        final enabled = await _isNotificationListenerEnabled();
        return enabled ? PermissionState.granted : PermissionState.notRequested;

      case PermissionType.notifications:
        final status = await Permission.notification.status;
        if (status.isGranted) return PermissionState.granted;
        if (status.isPermanentlyDenied) {
          return PermissionState.permanentlyDenied;
        }
        return PermissionState.notRequested;
    }
  }

  // ── Handle Allow tap ──

  Future<void> onAllowTap(int index) async {
    final items = permissions.value;
    final item = items[index];

    if (item.isGranted) return;

    switch (item.type) {
      case PermissionType.autostart:
        await _handleAutostart(item);
        break;

      case PermissionType.notificationAccess:
        await _handleNotificationAccess(item);
        break;

      case PermissionType.notifications:
        await _handleNotifications(item);
        break;
    }

    permissions.value = List.from(items);
    _updateAllGranted();
  }

  // ── Autostart → OEM settings page ──

  Future<void> _handleAutostart(PermissionItem item) async {
    try {
      final opened =
          await _channel.invokeMethod<bool>('openAutostartSettings') ?? false;
      if (opened) _autostartVisited = true;
    } catch (_) {}
    // Granted status updates on onResume
  }

  // ── Notification Access → listener settings ──

  Future<void> _handleNotificationAccess(PermissionItem item) async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
    // Granted status updates on onResume
  }

  // ── Notifications → system dialog, then settings if denied ──

  Future<void> _handleNotifications(PermissionItem item) async {
    if (item.status == PermissionState.permanentlyDenied) {
      // Already denied permanently → open app settings
      await openAppSettings();
      return;
    }

    // Show system permission dialog
    final result = await Permission.notification.request();
    if (result.isGranted) {
      item.status = PermissionState.granted;
    } else if (result.isPermanentlyDenied) {
      item.status = PermissionState.permanentlyDenied;
    }
  }

  // ── Refresh on resume ──

  Future<void> onResume() async {
    await _checkAllStatuses();
  }

  // ── Helpers ──

  void _updateAllGranted() {
    allGranted.value = permissions.value.every((p) => p.isGranted);
  }

  int get grantedCount => permissions.value.where((p) => p.isGranted).length;

  onContinue(BuildContext context) async {
    await PrefService.instance.setOnboardingDone(true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void dispose() {
    permissions.dispose();
    allGranted.dispose();
  }
}

// ── Models ───────────────────────────────────────────────────────────────────

enum PermissionType { autostart, notificationAccess, notifications }

enum PermissionState { notRequested, permanentlyDenied, granted }

class PermissionItem {
  final PermissionType type;
  final String title;
  final String description;
  final IconData icon;
  PermissionState status;

  PermissionItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.status = PermissionState.notRequested,
  });

  bool get isGranted => status == PermissionState.granted;
}
