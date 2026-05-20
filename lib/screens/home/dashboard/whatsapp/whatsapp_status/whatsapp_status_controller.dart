import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notification_manager/screens/home/dashboard/whatsapp/image_viewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notification_manager/screens/home/dashboard/whatsapp/video_preview_screen.dart';
import '../../dashboard_widgets.dart';

class StatusItem {
  final File file;
  final bool isSaved;

  StatusItem({required this.file, this.isSaved = false});

  bool get isVideo => file.path.toLowerCase().endsWith('.mp4');

  String get fileName => file.path.split('/').last;

  DateTime get modifiedAt => file.statSync().modified;
}

class WhatsAppStatusController {
  final BuildContext context;
  final TickerProvider vsync;

  WhatsAppStatusController({required this.context, required this.vsync});

  // --- ValueNotifiers ---
  final ValueNotifier<List<StatusItem>> recentItemsNotifier = ValueNotifier([]);
  final ValueNotifier<List<StatusItem>> savedItemsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);

  late TabController tabController;

  // Convenience getters (read-only)
  List<StatusItem> get recentItems => recentItemsNotifier.value;
  List<StatusItem> get savedItems => savedItemsNotifier.value;
  bool get isLoading => isLoadingNotifier.value;
  String? get errorMessage => errorMessageNotifier.value;

  static const List<String> _statusPaths = [
    "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
    "/storage/emulated/0/WhatsApp/Media/.Statuses",
    "/sdcard/WhatsApp/Media/.Statuses",
    "/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses",
  ];

  void init() {
    tabController = TabController(length: 2, vsync: vsync);
    fetchStatuses();
  }

  void dispose() {
    tabController.dispose();
    recentItemsNotifier.dispose();
    savedItemsNotifier.dispose();
    isLoadingNotifier.dispose();
    errorMessageNotifier.dispose();
  }

  Future<void> fetchStatuses() async {
    isLoadingNotifier.value = true;
    errorMessageNotifier.value = null;

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      isLoadingNotifier.value = false;
      errorMessageNotifier.value =
          "Storage permission is required to view statuses.";
      return;
    }

    List<StatusItem> found = [];
    for (final path in _statusPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        final files =
            dir.listSync().whereType<File>().where((f) {
              final lower = f.path.toLowerCase();
              return lower.endsWith('.jpg') ||
                  lower.endsWith('.jpeg') ||
                  lower.endsWith('.png') ||
                  lower.endsWith('.mp4');
            }).toList()..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );

        found = files.map((f) => StatusItem(file: f)).toList();
        break;
      }
    }

    final saved = await _loadSavedStatuses();

    recentItemsNotifier.value = found;
    savedItemsNotifier.value = saved;
    isLoadingNotifier.value = false;

    if (found.isEmpty) {
      errorMessageNotifier.value =
          "No statuses found.\nOpen WhatsApp and view some statuses first.";
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;
    return await Permission.storage.request().isGranted;
  }

  Future<List<StatusItem>> _loadSavedStatuses() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return [];
      final saveDir = Directory('${dir.path}/SavedStatuses');
      if (!await saveDir.exists()) return [];
      final files = saveDir.listSync().whereType<File>().toList()
        ..sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
      return files.map((f) => StatusItem(file: f, isSaved: true)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStatus(StatusItem item) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Cannot access storage");
      final saveDir = Directory('${dir.path}/SavedStatuses');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/${item.fileName}';
      if (await File(savePath).exists()) {
        _showSnackBar("Already saved!", isSuccess: false);
        return;
      }
      await item.file.copy(savePath);
      savedItemsNotifier.value = await _loadSavedStatuses();
      _showSnackBar("Status saved!", isSuccess: true);
    } catch (e) {
      _showSnackBar("Failed to save.", isSuccess: false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? primary : const Color(0xFF455A64),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void openPreview(StatusItem item, List<StatusItem> allItems) {
    final imageItems = allItems.where((e) => !e.isVideo).toList();
    final tappedIndex = imageItems.indexOf(item);

    if (item.isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VideoPreviewScreen(item: item, onSave: () => saveStatus(item)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          imagePaths: imageItems.map((e) => e.file.path).toList(),
          initialIndex: tappedIndex < 0 ? 0 : tappedIndex,
          onSave: (path) =>
              saveStatus(imageItems.firstWhere((e) => e.file.path == path)),
        ),
      ),
    );
  }
}
