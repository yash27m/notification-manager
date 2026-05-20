// lib/screens/chat_detail/chat_detail_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notification_manager/database/notification_db.dart';
import 'package:notification_manager/services/notification_engine.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDetailController {
  final Conversation conversation;

  ChatDetailController({required this.conversation});

  final ValueNotifier<List<ChatMessage>> messages =
      ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  StreamSubscription<NewMessageEvent>? _newMsgSub;
  StreamSubscription<MessageRemovedEvent>? _removedMsgSub;

  int _offset = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;

  // ── Init ──

  Future<void> init() async {
    isLoading.value = true;
    // Mark conversation as read
    await NotificationDB.instance.markConversationOpened(conversation.id);

    // Load first page
    _loadMessages();

    // Listen for live updates on this conversation
    _newMsgSub = NotificationEngine.instance.onNewMessage.listen((
      NewMessageEvent e,
    ) {
      if (e.conversationId == conversation.id) {
        // Prepend new message at top (newest first in DB, but we reverse for display)
        final List<ChatMessage> current = messages.value;
        messages.value = [e.message, ...current];

        // Mark as read immediately since user is viewing
        NotificationDB.instance.markConversationOpened(conversation.id);
      }
    });

    _removedMsgSub = NotificationEngine.instance.onMessageRemoved.listen((
      MessageRemovedEvent e,
    ) {
      if (e.conversationId == conversation.id) {
        // Refresh to show deleted status
        _offset = 0;
        _hasMore = true;
        _loadMessages();
      }
    });

    isLoading.value = false;
  }

  // ── Load messages (paginated) ──

  void _loadMessages() {
    final List<ChatMessage> msgs = NotificationDB.instance.getMessages(
      conversation.id,
      limit: _pageSize,
      offset: 0,
    );
    _offset = msgs.length;
    _hasMore = msgs.length >= _pageSize;
    messages.value = msgs;
  }

  // ── Load more (pagination) ──

  void loadMore() {
    if (!_hasMore) return;

    final List<ChatMessage> more = NotificationDB.instance.getMessages(
      conversation.id,
      limit: _pageSize,
      offset: _offset,
    );

    if (more.isEmpty) {
      _hasMore = false;
      return;
    }

    _offset += more.length;
    _hasMore = more.length >= _pageSize;
    messages.value = [...messages.value, ...more];
  }

  bool get hasMore => _hasMore;

  void redirectToApp(BuildContext context) async {
    String urlString = '';

    switch (conversation.packageName) {
      case 'com.whatsapp':
        urlString = 'https://wa.me/?text="';
        break;
      case 'com.instagram.android':
        urlString = 'instagram://direct-inbox';
        break;
      case 'org.telegram.messenger':
        urlString = 'tg://resolve';
        break;
      case 'com.facebook.orca':
        urlString = 'https://m.me';
        break;

      default:
        return;
    }
    final Uri url = Uri.parse(urlString);

    if (!await canLaunchUrl(url)) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'WhatsApp is not installed or could not be opened.',
        );
      }
      return;
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Failed to open WhatsApp. Please try again.');
      }
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Dispose ──

  void dispose() {
    _newMsgSub?.cancel();
    _removedMsgSub?.cancel();
    messages.dispose();
    isLoading.dispose();
  }
}
