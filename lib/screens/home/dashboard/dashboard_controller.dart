// lib/screens/dashboard/dashboard_controller.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/database/notification_db.dart';
import 'package:notification_manager/services/notification_engine.dart';

class DashboardController {
  final ValueNotifier<SelectedAppModel?> selectedApp =
      ValueNotifier<SelectedAppModel?>(null);
  final ValueNotifier<List<Conversation>> conversations =
      ValueNotifier<List<Conversation>>([]);
  final ValueNotifier<List<SelectedAppModel>> selectedApps =
      ValueNotifier<List<SelectedAppModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  final ValueNotifier<List<Conversation>> filteredConversations =
      ValueNotifier<List<Conversation>>([]);

  StreamSubscription<NewMessageEvent>? _newMsgSub;
  StreamSubscription<MessageRemovedEvent>? _removedMsgSub;

  static const Set<String> _whatsappPkgs = {'com.whatsapp', 'com.whatsapp.w4b'};

  bool get isWhatsApp =>
      selectedApp.value != null &&
      _whatsappPkgs.contains(selectedApp.value!.packageName);

  // ── Init ──

  Future<void> init() async {
    isLoading.value = true;
    final List<SelectedAppModel> apps = HiveService.instance.getSelectedApps();
    selectedApps.value = apps;

    if (apps.isNotEmpty) {
      final Iterable<SelectedAppModel> wa = apps.where(
        (a) => _whatsappPkgs.contains(a.packageName),
      );
      selectedApp.value = wa.isNotEmpty ? wa.first : apps.first;
    }

    _loadConversations();

    _newMsgSub = NotificationEngine.instance.onNewMessage.listen((
      NewMessageEvent e,
    ) {
      if (e.packageName == selectedApp.value?.packageName) _loadConversations();
    });

    _removedMsgSub = NotificationEngine.instance.onMessageRemoved.listen((
      MessageRemovedEvent e,
    ) {
      if (e.packageName == selectedApp.value?.packageName) _loadConversations();
    });
    isLoading.value = false;
  }

  // ── Switch app ──

  void switchApp(SelectedAppModel app) {
    selectedApp.value = app;
    _loadConversations();
  }

  // ── Load conversations for current app ──

  void _loadConversations() {
    final String? pkg = selectedApp.value?.packageName;
    if (pkg == null) {
      conversations.value = [];
      filteredConversations.value = [];
      return;
    }

    final allConversations = NotificationDB.instance.getConversations(pkg);
    conversations.value = allConversations;

    // Apply search filter immediately after loading
    _applySearchFilter();

    log('Loaded ${conversations.value.length} conversations for $pkg');
  }

  // 3. Add the search logic
  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final query = searchQuery.value.toLowerCase().trim();

    if (query.isEmpty) {
      filteredConversations.value = conversations.value;
    } else {
      filteredConversations.value = conversations.value.where((conv) {
        // Assuming 'id' or a 'title/senderName' property exists in your Conversation model
        // Replace 'id' with 'senderName' or 'title' as per your model
        final contactName = conv.title.toLowerCase();
        final lastMsg = conv.lastMessage.toLowerCase();

        return contactName.contains(query) || lastMsg.contains(query);
      }).toList();
    }
  }

  void refresh() => _loadConversations();

  // ── Mark opened ──

  Future<void> markOpened(String conversationId) async {
    await NotificationDB.instance.markConversationOpened(conversationId);
    _loadConversations();
  }

  // ── Manage apps (bottom sheet) ──

  Future<void> updateSelectedApps(List<SelectedAppModel> newList) async {
    await HiveService.instance.saveSelectedApps(newList);
    selectedApps.value = newList;

    final String? currentPkg = selectedApp.value?.packageName;
    if (currentPkg != null &&
        !newList.any((a) => a.packageName == currentPkg)) {
      selectedApp.value = newList.isNotEmpty ? newList.first : null;
      _loadConversations();
    }
  }

  // ── Unread badge ──

  int getUnreadCount(String packageName) =>
      NotificationDB.instance.getUnreadCount(packageName);

  // ── Dispose ──

  void dispose() {
    _newMsgSub?.cancel();
    _removedMsgSub?.cancel();
    selectedApp.dispose();
    conversations.dispose();
    selectedApps.dispose();
    isLoading.dispose();
    searchQuery.dispose();
    filteredConversations.dispose();
  }
}
