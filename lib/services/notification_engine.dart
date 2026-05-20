// lib/services/notification_engine.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/database/notification_db.dart';
import 'package:notification_manager/services/notification_parser.dart';

class NotificationEngine {
  NotificationEngine._();
  static final instance = NotificationEngine._();

  static const _eventChannel =
      EventChannel('com.example.notification_manager/notifications');

  StreamSubscription<dynamic>? _subscription;

  final _onNewMessage = StreamController<NewMessageEvent>.broadcast();
  Stream<NewMessageEvent> get onNewMessage => _onNewMessage.stream;

  final _onMessageRemoved = StreamController<MessageRemovedEvent>.broadcast();
  Stream<MessageRemovedEvent> get onMessageRemoved => _onMessageRemoved.stream;

  void init() {
    _subscription = _eventChannel.receiveBroadcastStream().listen(
          _handleNotification,
          onError: (Object e) => print('NotificationEngine error: $e'),
        );
  }

  Set<String> get _selectedPackages {
    return HiveService.instance.getSelectedApps().map((a) => a.packageName).toSet();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ENTRY POINT
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _handleNotification(dynamic data) async {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final String action = map['action'] as String? ?? '';
    final String packageName = map['packageName'] as String? ?? '';

    if (!_selectedPackages.contains(packageName)) return;

    if (action == 'posted') {
      await _onPosted(map);
    } else if (action == 'removed') {
      await _onRemoved(map);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // POSTED — parse via NotificationParser then store
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _onPosted(Map<String, dynamic> map) async {
    final String packageName = map['packageName'] as String;
    final String title = (map['title'] as String? ?? '').trim();
    final String rawText = (map['text'] as String? ?? '').trim();
    final String subText = (map['subText'] as String? ?? '').trim();
    final String bigText = (map['bigText'] as String? ?? '').trim();
    final String text = bigText.length > rawText.length ? bigText : rawText;
    final String sysConvTitle = (map['conversationTitle'] as String? ?? '').trim();
    final int timestamp =
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final String category = map['category'] as String? ?? '';
    final Uint8List? avatar = map['largeIcon'] as Uint8List?;
    final Uint8List? picture = map['picture'] as Uint8List?;
    final bool isOngoing = map['isOngoing'] as bool? ?? false;

    if (title.isEmpty && text.isEmpty) return;
    if (isOngoing) return;

    // ── Parse via universal parser ──
    final ParsedNotification parsed = NotificationParser.parse(
      packageName: packageName,
      title: title,
      text: text,
      subText: subText,
      category: category,
      sysConvTitle: sysConvTitle,
    );

    if (parsed.shouldSkip) return;

    // ── Store in DB ──
    final NotificationDB db = NotificationDB.instance;

    final Conversation conv = await db.getOrCreateConversation(
      packageName: packageName,
      title: parsed.conversationTitle,
      isGroup: parsed.isGroup,
      avatar: avatar,
    );

    final ChatMessage msg = await db.addMessage(
      conversationId: conv.id,
      packageName: packageName,
      senderName: parsed.senderName,
      text: parsed.messageText,
      timestamp: timestamp,
      type: parsed.messageType,
      thumbnail: picture,
    );

    _onNewMessage.add(NewMessageEvent(
      packageName: packageName,
      conversationId: conv.id,
      message: msg,
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // REMOVED — deleted message tracking
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _onRemoved(Map<String, dynamic> map) async {
    final String packageName = map['packageName'] as String;
    final String title = (map['title'] as String? ?? '').trim();
    final String text = (map['text'] as String? ?? '').trim();
    final String sysConvTitle = (map['conversationTitle'] as String? ?? '').trim();
    final int timestamp =
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    if (title.isEmpty) return;

    // Use parser to get the same clean conversation title
    final ParsedNotification parsed = NotificationParser.parse(
      packageName: packageName,
      title: title,
      text: text,
      subText: '',
      category: '',
      sysConvTitle: sysConvTitle,
    );

    if (parsed.shouldSkip) return;

    final String convId =
        NotificationDB.makeConversationId(packageName, parsed.conversationTitle);
    await NotificationDB.instance.markMessageRemoved(convId, text, timestamp);

    _onMessageRemoved.add(MessageRemovedEvent(
      packageName: packageName,
      conversationId: convId,
      text: text,
    ));
  }

  void dispose() {
    _subscription?.cancel();
    _onNewMessage.close();
    _onMessageRemoved.close();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EVENTS
// ═════════════════════════════════════════════════════════════════════════════

class NewMessageEvent {
  final String packageName;
  final String conversationId;
  final ChatMessage message;
  const NewMessageEvent({
    required this.packageName,
    required this.conversationId,
    required this.message,
  });
}

class MessageRemovedEvent {
  final String packageName;
  final String conversationId;
  final String text;
  const MessageRemovedEvent({
    required this.packageName,
    required this.conversationId,
    required this.text,
  });
}