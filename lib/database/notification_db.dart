// lib/database/notification_db.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

part 'notification_db.g.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL: Conversation
// ═══════════════════════════════════════════════════════════════════════════════

@HiveType(typeId: 1)
class Conversation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String packageName;

  @HiveField(2)
  String title;

  @HiveField(3)
  String lastMessage;

  @HiveField(4)
  int lastTimestamp;

  @HiveField(5)
  int unreadCount;

  @HiveField(6)
  bool isGroup;

  @HiveField(7)
  Uint8List? avatar;

  @HiveField(8)
  int totalMessages;

  @HiveField(9)
  int lastOpenedTimestamp;

  @HiveField(10)
  String? lastSenderInGroup;

  Conversation({
    required this.id,
    required this.packageName,
    required this.title,
    this.lastMessage = '',
    this.lastTimestamp = 0,
    this.unreadCount = 0,
    this.isGroup = false,
    this.avatar,
    this.totalMessages = 0,
    this.lastOpenedTimestamp = 0,
    this.lastSenderInGroup,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL: ChatMessage
// ═══════════════════════════════════════════════════════════════════════════════

@HiveType(typeId: 2)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String packageName;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  String text;

  @HiveField(5)
  int timestamp;

  @HiveField(6)
  int type;

  @HiveField(7)
  bool isRemoved;

  @HiveField(8)
  Uint8List? thumbnail;

  @HiveField(9)
  String? extras;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.packageName,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = 0,
    this.isRemoved = false,
    this.thumbnail,
    this.extras,
  });

  // ── Convenience getters ──

  bool get isImage => type == MessageType.image && thumbnail != null;
  bool get isVideo => type == MessageType.video && thumbnail != null;
  bool get hasMedia => thumbnail != null;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE TYPE (int constants — no Hive adapter needed)
// ═══════════════════════════════════════════════════════════════════════════════

class MessageType {
  MessageType._();
  static const int text = 0;
  static const int image = 1;
  static const int video = 2;
  static const int audio = 3;
  static const int document = 4;
  static const int call = 5;
  static const int missedCall = 6;
  static const int voiceNote = 7;
  static const int sticker = 8;
  static const int location = 9;
  static const int contact = 10;
  static const int reaction = 11;
  static const int status = 12;
  static const int unknown = 99;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATABASE SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationDB {
  NotificationDB._();
  static final instance = NotificationDB._();

  late final Box<Conversation> _convBox;
  late final Box<ChatMessage> _msgBox;
  bool _initialized = false;

  final Map<String, List<String>> _appConvIndex = {};

  // ── Init ──

  Future<void> init() async {
    if (_initialized) return;
    Hive.registerAdapter(ConversationAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    _convBox = await Hive.openBox<Conversation>('conversations');
    _msgBox = await Hive.openBox<ChatMessage>('messages');
    _rebuildIndexes();
    _initialized = true;
  }

  void _rebuildIndexes() {
    _appConvIndex.clear();
    for (final conv in _convBox.values) {
      _appConvIndex.putIfAbsent(conv.packageName, () => []);
      _appConvIndex[conv.packageName]!.add(conv.id);
    }
    for (final key in _appConvIndex.keys) {
      _appConvIndex[key]!.sort((a, b) {
        final ca = _convBox.get(a);
        final cb = _convBox.get(b);
        if (ca == null || cb == null) return 0;
        return cb.lastTimestamp.compareTo(ca.lastTimestamp);
      });
    }
  }

  // ── Conversation ID generator ──

  static String makeConversationId(String packageName, String title) {
    final hash = md5
        .convert(utf8.encode('$packageName|${title.trim().toLowerCase()}'))
        .toString();
    return '$packageName|$hash';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CONVERSATION CRUD
  // ═════════════════════════════════════════════════════════════════════════

  Future<Conversation> getOrCreateConversation({
    required String packageName,
    required String title,
    bool isGroup = false,
    Uint8List? avatar,
  }) async {
    final id = makeConversationId(packageName, title);
    var conv = _convBox.get(id);

    if (conv != null) {
      if (avatar != null && avatar.isNotEmpty) {
        conv.avatar = avatar;
        await conv.save();
      }
      return conv;
    }

    conv = Conversation(
      id: id,
      packageName: packageName,
      title: title,
      isGroup: isGroup,
      avatar: avatar,
    );
    await _convBox.put(id, conv);
    _appConvIndex.putIfAbsent(packageName, () => []);
    _appConvIndex[packageName]!.insert(0, id);
    return conv;
  }

  List<Conversation> getConversations(String packageName) {
    final ids = _appConvIndex[packageName];
    if (ids == null || ids.isEmpty) return [];
    return ids.map((id) => _convBox.get(id)).whereType<Conversation>().toList();
  }

  Conversation? getConversation(String id) => _convBox.get(id);

  Future<void> markConversationOpened(String id) async {
    final conv = _convBox.get(id);
    if (conv == null) return;
    conv.unreadCount = 0;
    conv.lastOpenedTimestamp = DateTime.now().millisecondsSinceEpoch;
    await conv.save();
  }

  Future<void> deleteConversation(String id) async {
    final conv = _convBox.get(id);
    if (conv == null) return;
    final keys = _msgBox
        .toMap()
        .entries
        .where((e) => e.value.conversationId == id)
        .map((e) => e.key)
        .toList();
    await _msgBox.deleteAll(keys);
    await _convBox.delete(id);
    _appConvIndex[conv.packageName]?.remove(id);
  }

  int getUnreadCount(String packageName) {
    return getConversations(packageName).fold(0, (s, c) => s + c.unreadCount);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MESSAGE CRUD
  // ═════════════════════════════════════════════════════════════════════════

  Future<ChatMessage> addMessage({
    required String conversationId,
    required String packageName,
    required String senderName,
    required String text,
    required int timestamp,
    int type = 0,
    Uint8List? thumbnail,
  }) async {
    // Dedup
    if (_isDuplicate(conversationId, text, timestamp)) {
      return _msgBox.values.firstWhere(
        (m) =>
            m.conversationId == conversationId &&
            m.text == text &&
            (m.timestamp - timestamp).abs() < 2000,
      );
    }

    final msgId = '$conversationId|$timestamp|${text.hashCode}';
    final msg = ChatMessage(
      id: msgId,
      conversationId: conversationId,
      packageName: packageName,
      senderName: senderName,
      text: text,
      timestamp: timestamp,
      type: type,
      thumbnail: thumbnail,
    );
    await _msgBox.put(msgId, msg);

    // Update conversation
    final conv = _convBox.get(conversationId);
    if (conv != null) {
      conv.lastMessage = _formatLastMessage(
        senderName,
        text,
        type,
        conv.isGroup,
      );
      conv.lastTimestamp = timestamp;
      conv.unreadCount += 1;
      conv.totalMessages += 1;
      if (conv.isGroup) conv.lastSenderInGroup = senderName;
      await conv.save();
      _appConvIndex[packageName]?.remove(conversationId);
      _appConvIndex[packageName]?.insert(0, conversationId);
    }

    return msg;
  }

  List<ChatMessage> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) {
    final list =
        _msgBox.values.where((m) => m.conversationId == conversationId).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (offset >= list.length) return [];
    return list.sublist(offset, (offset + limit).clamp(0, list.length));
  }

  /// Returns only messages that have a thumbnail (images/videos)
  List<ChatMessage> getMediaMessages(String conversationId) {
    return _msgBox.values
        .where((m) => m.conversationId == conversationId && m.thumbnail != null)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> markMessageRemoved(
    String conversationId,
    String text,
    int timestamp,
  ) async {
    for (final msg in _msgBox.values) {
      if (msg.conversationId == conversationId &&
          msg.text == text &&
          (msg.timestamp - timestamp).abs() < 5000) {
        msg.isRemoved = true;
        await msg.save();
        return;
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  bool _isDuplicate(String conversationId, String text, int timestamp) {
    for (final msg in _msgBox.values) {
      if (msg.conversationId == conversationId &&
          msg.text == text &&
          (msg.timestamp - timestamp).abs() < 2000)
        return true;
    }
    return false;
  }

  String _formatLastMessage(
    String sender,
    String text,
    int type,
    bool isGroup,
  ) {
    final p = isGroup ? '$sender: ' : '';
    switch (type) {
      case MessageType.image:
        return '$p📷 Photo';
      case MessageType.video:
        return '$p🎥 Video';
      case MessageType.audio:
        return '$p🎵 Audio';
      case MessageType.voiceNote:
        return '$p🎤 Voice message';
      case MessageType.document:
        return '$p📄 Document';
      case MessageType.call:
        return '📞 Call';
      case MessageType.missedCall:
        return '📞 Missed call';
      case MessageType.sticker:
        return '$p🏷️ Sticker';
      case MessageType.location:
        return '$p📍 Location';
      case MessageType.contact:
        return '$p👤 Contact';
      case MessageType.status:
        return 'Status update';
      default:
        return '$p$text';
    }
  }

  Future<void> clearAppData(String packageName) async {
    for (final id in List<String>.from(_appConvIndex[packageName] ?? [])) {
      await deleteConversation(id);
    }
    _appConvIndex.remove(packageName);
  }

  Future<void> compact() async {
    await _convBox.compact();
    await _msgBox.compact();
  }
}
