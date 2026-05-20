import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'hive_service.g.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class SelectedAppModel extends HiveObject {
  @HiveField(0)
  final String packageName;

  @HiveField(1)
  final String appName;

  @HiveField(2)
  final Uint8List? icon;

  SelectedAppModel({
    required this.packageName,
    required this.appName,
    this.icon,
  });
}

@HiveType(typeId: 3)
class DialHistoryEntryModel extends HiveObject {
  @HiveField(0)
  final String phoneNumber;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final DateTime calledAt;

  DialHistoryEntryModel({
    required this.phoneNumber,
    required this.message,
    required this.calledAt,
  });
}

// ─── Service ─────────────────────────────────────────────────────────────────

class HiveService {
  HiveService._();
  static final instance = HiveService._();

  static const _appsBoxName = 'selected_apps';
  static const _historyBoxName = 'dial_history';

  late Box<SelectedAppModel> _appsBox;
  late Box<DialHistoryEntryModel> _historyBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SelectedAppModelAdapter());
    Hive.registerAdapter(DialHistoryEntryModelAdapter());
    _appsBox = await Hive.openBox<SelectedAppModel>(_appsBoxName);
    _historyBox = await Hive.openBox<DialHistoryEntryModel>(_historyBoxName);
  }

  // ── Selected apps ─────────────────────────────────────────────────────────

  Future<void> saveSelectedApps(List<SelectedAppModel> apps) async {
    await _appsBox.clear();
    for (final app in apps) {
      await _appsBox.put(app.packageName, app);
    }
  }

  Future<void> addApp(SelectedAppModel app) async {
    await _appsBox.put(app.packageName, app);
  }

  List<SelectedAppModel> getSelectedApps() => _appsBox.values.toList();

  SelectedAppModel? getApp(String packageName) => _appsBox.get(packageName);

  bool isAppSaved(String packageName) => _appsBox.containsKey(packageName);

  Future<void> removeApp(String packageName) async {
    await _appsBox.delete(packageName);
  }

  Future<void> clearAll() async {
    await _appsBox.clear();
  }

  // ── Dial history ──────────────────────────────────────────────────────────

  List<DialHistoryEntryModel> getDialHistory() {
    final list = _historyBox.values.toList();
    list.sort((a, b) => b.calledAt.compareTo(a.calledAt));
    return list;
  }

  Future<void> addDialEntry(DialHistoryEntryModel entry) async {
    await _historyBox.add(entry);
  }

  Future<void> removeDialEntry(DialHistoryEntryModel entry) async {
    await entry.delete();
  }

  Future<void> clearDialHistory() async {
    await _historyBox.clear();
  }
}
