import 'package:notification_manager/database/notification_db.dart';

/// Parsed result from a raw notification
class ParsedNotification {
  final String conversationTitle; // cleaned, consistent key for grouping
  final String senderName;
  final String messageText;
  final int messageType;
  final bool isGroup;
  final bool shouldSkip;

  const ParsedNotification({
    required this.conversationTitle,
    required this.senderName,
    required this.messageText,
    this.messageType = MessageType.text,
    this.isGroup = false,
    this.shouldSkip = false,
  });

  const ParsedNotification.skip()
    : conversationTitle = '',
      senderName = '',
      messageText = '',
      messageType = MessageType.text,
      isGroup = false,
      shouldSkip = true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION PARSER — universal + app-specific rules
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationParser {
  NotificationParser._();

  /// Main entry — routes to app-specific parser or general
  static ParsedNotification parse({
    required String packageName,
    required String title,
    required String text,
    required String subText,
    required String category,
    String sysConvTitle = '',
  }) {
    if (title.isEmpty && text.isEmpty) return const ParsedNotification.skip();

    // Route to app-specific parser
    final String? appKey = _appParserKey(packageName);
    switch (appKey) {
      case 'whatsapp':
        return _WhatsAppParser.parse(title, text, subText, category, sysConvTitle);
      case 'telegram':
        return _TelegramParser.parse(title, text, subText, category, sysConvTitle);
      case 'instagram':
        return _InstagramParser.parse(title, text, subText, category, sysConvTitle);
      case 'facebook':
        return _FacebookParser.parse(title, text, subText, category, sysConvTitle);
      case 'slack':
        return _SlackParser.parse(title, text, subText, category, sysConvTitle);
      case 'discord':
        return _DiscordParser.parse(title, text, subText, category, sysConvTitle);
      case 'snapchat':
        return _SnapchatParser.parse(title, text, subText, category, sysConvTitle);
      default:
        return _GeneralParser.parse(title, text, category, sysConvTitle);
    }
  }

  static String? _appParserKey(String packageName) {
    const Map<String, String> map = {
      'com.whatsapp': 'whatsapp',
      'com.whatsapp.w4b': 'whatsapp',
      'org.telegram.messenger': 'telegram',
      'com.instagram.android': 'instagram',
      'com.facebook.katana': 'facebook',
      'com.facebook.orca': 'facebook',
      'com.Slack': 'slack',
      'com.discord': 'discord',
      'com.snapchat.android': 'snapchat',
    };
    return map[packageName];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED UTILITIES
// ═══════════════════════════════════════════════════════════════════════════════

class _Utils {
  /// Remove patterns like "(2 messages)", "(38 messages): ...", "(2 m..."
  static String removeMessageCount(String title) {
    return title
        .replaceAll(RegExp(r'\s*\(\d+\s*m[^)]*\)[\s:]*'), ' ')
        .replaceAll(RegExp(r'\s*\(\d+\s*new[^)]*\)[\s:]*'), ' ')
        .replaceAll(RegExp(r'\s*\(\d+\)[\s:]*'), ' ')
        .replaceAll(RegExp(r'\s*\[\d+\][\s:]*'), ' ')
        .trim();
  }

  /// Remove "N new messages" / "N messages" standalone text
  static bool isSummaryText(String text) {
    return RegExp(
      r'^\d+\s+(new\s+)?messages?$',
      caseSensitive: false,
    ).hasMatch(text.trim());
  }

  /// Remove trailing "..." / ellipsis
  static String removeEllipsis(String text) {
    return text.replaceAll(RegExp(r'[\.…]+$'), '').trim();
  }

  /// Extract "Sender: Message" pattern. Returns null if not found.
  static ({String sender, String message})? extractSenderMessage(
    String text, {
    int maxColonPos = 50,
  }) {
    final int idx = text.indexOf(': ');
    if (idx <= 0 || idx > maxColonPos) return null;
    final String sender = text.substring(0, idx).trim();
    final String message = text.substring(idx + 2).trim();
    if (sender.isEmpty || message.isEmpty) return null;
    return (sender: sender, message: message);
  }

  /// Detect call from category or text
  static bool isCall(String category, String text) {
    if (category == 'call') return true;
    final String lower = text.toLowerCase();
    return lower.contains('incoming call') ||
        lower.contains('outgoing call') ||
        lower.contains('missed call') ||
        lower.contains('ongoing call') ||
        lower.contains('video call') ||
        lower.contains('ringing');
  }

  static int callType(String text) {
    return text.toLowerCase().contains('missed')
        ? MessageType.missedCall
        : MessageType.call;
  }

  /// Detect message type from emoji/keyword patterns
  static int detectMediaType(String text) {
    final String lower = text.toLowerCase();
    if (lower.contains('📷') || lower == 'photo' || lower == 'image')
      return MessageType.image;
    if (lower.contains('🎥') || lower == 'video') return MessageType.video;
    if (lower.contains('🎵') || lower == 'audio') return MessageType.audio;
    if (lower.contains('🎤') ||
        lower.contains('voice message') ||
        lower.contains('ptt'))
      return MessageType.voiceNote;
    if (lower.contains('📄') || lower == 'document' || lower.contains('.pdf'))
      return MessageType.document;
    if (lower.contains('🏷️') || lower == 'sticker') return MessageType.sticker;
    if (lower.contains('📍') || lower.contains('location'))
      return MessageType.location;
    if (lower.contains('👤') || lower.contains('contact card'))
      return MessageType.contact;
    if (lower.contains('gif')) return MessageType.sticker;
    return MessageType.text;
  }

  /// Check if title is a summary/header notification
  static bool isSummaryTitle(String title, List<String> appNames) {
    final String lower = title.toLowerCase();
    // "N new messages", "N new notifications"
    if (RegExp(r'^\d+\s+(new\s+)?(message|notification)').hasMatch(lower))
      return true;
    // Title is just the app name
    for (final String name in appNames) {
      if (lower == name.toLowerCase()) return true;
    }
    return false;
  }

  /// Strip "sender: " prefix from title if it exists, return group name
  static String stripSenderFromTitle(String title) {
    // "Group Name: SenderName" or "Group Name: Sende..."
    final int colonIdx = title.lastIndexOf(':');
    if (colonIdx > 0) {
      final String before = title.substring(0, colonIdx).trim();
      final String after = title.substring(colonIdx + 1).trim();
      // If after colon looks like a name (not a URL or time)
      if (after.isNotEmpty &&
          !after.contains('//') &&
          !RegExp(r'^\d{1,2}:\d{2}').hasMatch(after)) {
        return before;
      }
    }
    return title;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WHATSAPP
// Patterns:
//   Personal: title="John", text="Hello"
//   Group:    title="Group Name", text="Sender: Hello"
//   Summary:  title="Group (2 messages): Sender...", text="message"
//   Summary:  title="5 new messages", text=ignored
// ═══════════════════════════════════════════════════════════════════════════════

class _WhatsAppParser {
  static const List<String> _appNames = ['WhatsApp', 'WhatsApp Business'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    // Skip summaries
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    // Calls
    if (_Utils.isCall(category, text)) {
      final String clean = _cleanTitle(title, subText);
      return ParsedNotification(
        conversationTitle: clean,
        senderName: clean,
        messageText: text,
        messageType: _Utils.callType(text),
      );
    }

    bool isGroup = false;
    String conversationTitle = '';
    String senderName = '';
    String messageText = text;

    // Use sysConvTitle if available (it represents the true group name)
    if (sysConvTitle.isNotEmpty) {
      isGroup = true;
      String cleanSysConv = _Utils.removeMessageCount(sysConvTitle);
      conversationTitle = _Utils.removeEllipsis(cleanSysConv).trim();

      // The title from Android often contains both for WhatsApp (e.g., "GroupName SenderName")
      // If we know the true GroupName, we can extract the SenderName.
      senderName = _extractSenderFromTitle(title, conversationTitle);
      if (senderName.isEmpty) senderName = title; // fallback

      // Sometimes text is "Sender: message"
      final senderMsg = _Utils.extractSenderMessage(text, maxColonPos: 40);
      if (senderMsg != null) {
        messageText = senderMsg.message;
        senderName = senderMsg.sender; // prefer sender from text if explicit
      }
    } else {
      // ── Could be personal OR group without subText ──
      final String cleanTitle = _cleanTitle(title, subText);

      // Check text for "Sender: Message" pattern (group format)
      final senderMsg = _Utils.extractSenderMessage(text, maxColonPos: 40);
      if (senderMsg != null && senderMsg.sender != cleanTitle) {
        isGroup = true;
        conversationTitle = cleanTitle;
        senderName = senderMsg.sender;
        messageText = senderMsg.message;
      } else {
        // Personal message
        conversationTitle = cleanTitle;
        senderName = cleanTitle;
      }
    }

    // Skip summary texts like "3 new messages"
    if (_Utils.isSummaryText(messageText)) {
      return const ParsedNotification.skip();
    }

    return ParsedNotification(
      conversationTitle: conversationTitle,
      senderName: senderName,
      messageText: messageText,
      messageType: _Utils.detectMediaType(messageText),
      isGroup: isGroup,
    );
  }

  /// Extract sender name from title by removing the group name prefix
  /// e.g. title="Learn by Fun Patidev ❤️", groupName="Learn by Fun" → "Patidev ❤️"
  static String _extractSenderFromTitle(String title, String groupName) {
    String cleanTitle = _Utils.removeMessageCount(title);

    // Try removing group name prefix
    if (cleanTitle.startsWith(groupName)) {
      String remainder = cleanTitle.substring(groupName.length).trim();
      // Remove leading : or -
      if (remainder.startsWith(':') || remainder.startsWith('-')) {
        remainder = remainder.substring(1).trim();
      }
      remainder = _Utils.removeEllipsis(remainder).trim();
      if (remainder.isNotEmpty) return remainder;
    }

    String clean = _Utils.stripSenderFromTitle(cleanTitle);
    clean = _Utils.removeEllipsis(clean).trim();
    if (clean != groupName && clean.isNotEmpty) return clean;

    return '';
  }

  static String _cleanTitle(String title, String subText) {
    // If subText available, prefer it
    if (subText.isNotEmpty) {
      return _Utils.removeEllipsis(_Utils.removeMessageCount(subText)).trim();
    }
    String clean = _Utils.removeMessageCount(title);
    clean = _Utils.stripSenderFromTitle(clean);
    return _Utils.removeEllipsis(clean).trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TELEGRAM
// Patterns:
//   Personal: title="John", text="Hello"
//   Group:    title="Group Name", text="Sender: Hello"
//   Channel:  title="Channel Name", text="message"
//   Summary:  title="Telegram", text="N new messages..."
// ═══════════════════════════════════════════════════════════════════════════════

class _TelegramParser {
  static const List<String> _appNames = ['Telegram'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    if (_Utils.isCall(category, text)) {
      return ParsedNotification(
        conversationTitle: title,
        senderName: title,
        messageText: text,
        messageType: _Utils.callType(text),
      );
    }

    bool isGroup = false;
    String senderName = title;
    String messageText = text;

    // Telegram puts sender in text for groups: "Sender: message"
    final senderMsg = _Utils.extractSenderMessage(text);
    if (senderMsg != null && senderMsg.sender != title) {
      isGroup = true;
      senderName = senderMsg.sender;
      messageText = senderMsg.message;
    }

    return ParsedNotification(
      conversationTitle: title,
      senderName: senderName,
      messageText: messageText,
      messageType: _Utils.detectMediaType(messageText),
      isGroup: isGroup,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INSTAGRAM
// Patterns:
//   DM:      title="username", text="message"
//   Story:   title="username", text="added to their Story"
//   Like:    title="Instagram", text="username liked your..."
//   Follow:  title="Instagram", text="username started following..."
//   Group:   title="Group Name", text="username: message"
// ═══════════════════════════════════════════════════════════════════════════════

class _InstagramParser {
  static const List<String> _appNames = ['Instagram'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    // Instagram activity notifications (likes, follows) — group under "Instagram"
    if (title == 'Instagram') {
      return ParsedNotification(
        conversationTitle: 'Instagram Activity',
        senderName: 'Instagram',
        messageText: text,
        messageType: MessageType.status,
      );
    }

    bool isGroup = false;
    String senderName = title;
    String messageText = text;

    // Story notifications
    if (text.contains('added to their Story') || text.contains('Story')) {
      return ParsedNotification(
        conversationTitle: title,
        senderName: title,
        messageText: text,
        messageType: MessageType.status,
      );
    }

    // Group DM: text="sender: message"
    final senderMsg = _Utils.extractSenderMessage(text);
    if (senderMsg != null && senderMsg.sender != title) {
      isGroup = true;
      senderName = senderMsg.sender;
      messageText = senderMsg.message;
    }

    return ParsedNotification(
      conversationTitle: title,
      senderName: senderName,
      messageText: messageText,
      messageType: _Utils.detectMediaType(messageText),
      isGroup: isGroup,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FACEBOOK / MESSENGER
// Patterns:
//   Messenger: title="Name", text="message"
//   Group:     title="Group", text="Name: message"
//   Facebook:  title="Facebook", text="Name commented..."
//   Reactions: title="Name reacted to your message"
// ═══════════════════════════════════════════════════════════════════════════════

class _FacebookParser {
  static const List<String> _appNames = ['Facebook', 'Messenger'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    // Facebook activity (not messenger)
    if (title == 'Facebook') {
      return ParsedNotification(
        conversationTitle: 'Facebook Activity',
        senderName: 'Facebook',
        messageText: text,
        messageType: MessageType.status,
      );
    }

    if (_Utils.isCall(category, text)) {
      return ParsedNotification(
        conversationTitle: title,
        senderName: title,
        messageText: text,
        messageType: _Utils.callType(text),
      );
    }

    String clean = _Utils.removeMessageCount(title);
    bool isGroup = false;
    String senderName = clean;
    String messageText = text;

    // Reaction notifications
    if (text.contains('reacted')) {
      return ParsedNotification(
        conversationTitle: clean,
        senderName: clean,
        messageText: text,
        messageType: MessageType.reaction,
      );
    }

    final senderMsg = _Utils.extractSenderMessage(text);
    if (senderMsg != null && senderMsg.sender != clean) {
      isGroup = true;
      senderName = senderMsg.sender;
      messageText = senderMsg.message;
    }

    return ParsedNotification(
      conversationTitle: clean,
      senderName: senderName,
      messageText: messageText,
      messageType: _Utils.detectMediaType(messageText),
      isGroup: isGroup,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLACK
// Patterns:
//   DM:      title="Name", text="message", subText="Workspace"
//   Channel: title="#channel", text="Name: message", subText="Workspace"
//   Thread:  title="Thread in #channel", text="Name: message"
//   Summary: title="Slack", text="N new messages"
// ═══════════════════════════════════════════════════════════════════════════════

class _SlackParser {
  static const List<String> _appNames = ['Slack'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    // Clean workspace suffix — "Channel • Workspace" → "Channel"
    String cleanTitle = title.replaceAll(RegExp(r'\s*[•·]\s*.*$'), '').trim();

    // Thread prefix — "Thread in #channel" → "#channel"
    cleanTitle = cleanTitle.replaceFirst(
      RegExp(r'^Thread\s+in\s+', caseSensitive: false),
      '',
    );

    bool isGroup = cleanTitle.startsWith('#');
    String senderName = cleanTitle;
    String messageText = text;

    final senderMsg = _Utils.extractSenderMessage(text);
    if (senderMsg != null) {
      senderName = senderMsg.sender;
      messageText = senderMsg.message;
      if (cleanTitle.startsWith('#')) isGroup = true;
    }

    return ParsedNotification(
      conversationTitle: cleanTitle,
      senderName: senderName,
      messageText: messageText,
      messageType: _Utils.detectMediaType(messageText),
      isGroup: isGroup,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISCORD
// Patterns:
//   DM:      title="Username", text="message"
//   Server:  title="Username (#channel, Server)", text="message"
//   Summary: title="Discord", text="N new messages"
// ═══════════════════════════════════════════════════════════════════════════════

class _DiscordParser {
  static const List<String> _appNames = ['Discord'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    if (_Utils.isCall(category, text)) {
      return ParsedNotification(
        conversationTitle: title,
        senderName: title,
        messageText: text,
        messageType: _Utils.callType(text),
      );
    }

    // "Username (#channel, Server)" → channel = "Server > #channel", sender = "Username"
    final match = RegExp(r'^(.+?)\s*\(#(.+?),\s*(.+?)\)$').firstMatch(title);
    if (match != null) {
      final String sender = match.group(1)!.trim();
      final String channel = match.group(2)!.trim();
      final String server = match.group(3)!.trim();
      return ParsedNotification(
        conversationTitle: '$server > #$channel',
        senderName: sender,
        messageText: text,
        messageType: _Utils.detectMediaType(text),
        isGroup: true,
      );
    }

    // DM
    return ParsedNotification(
      conversationTitle: title,
      senderName: title,
      messageText: text,
      messageType: _Utils.detectMediaType(text),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SNAPCHAT
// Patterns:
//   Snap:    title="Username", text="New Snap"
//   Chat:    title="Username", text="New Chat"
//   Story:   title="Username", text="added to their Story"
//   Group:   title="Group Name", text="Username: message"
// ═══════════════════════════════════════════════════════════════════════════════

class _SnapchatParser {
  static const List<String> _appNames = ['Snapchat'];

  static ParsedNotification parse(
    String title,
    String text,
    String subText,
    String category,
    String sysConvTitle,
  ) {
    if (_Utils.isSummaryTitle(title, _appNames))
      return const ParsedNotification.skip();
    if (title.isEmpty) return const ParsedNotification.skip();

    bool isGroup = false;
    String senderName = title;
    String messageText = text;

    // Story
    if (text.contains('Story')) {
      return ParsedNotification(
        conversationTitle: title,
        senderName: title,
        messageText: text,
        messageType: MessageType.status,
      );
    }

    // Group chat
    final senderMsg = _Utils.extractSenderMessage(text);
    if (senderMsg != null && senderMsg.sender != title) {
      isGroup = true;
      senderName = senderMsg.sender;
      messageText = senderMsg.message;
    }

    // Detect snap/chat type
    int type = MessageType.text;
    final String lower = messageText.toLowerCase();
    if (lower.contains('new snap'))
      type = MessageType.image;
    else if (lower.contains('new chat'))
      type = MessageType.text;
    else
      type = _Utils.detectMediaType(messageText);

    return ParsedNotification(
      conversationTitle: title,
      senderName: senderName,
      messageText: messageText,
      messageType: type,
      isGroup: isGroup,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENERAL (fallback for all other apps)
// ═══════════════════════════════════════════════════════════════════════════════

class _GeneralParser {
  static ParsedNotification parse(String title, String text, String category, String sysConvTitle) {
    if (title.isEmpty) return const ParsedNotification.skip();

    // Calls
    if (_Utils.isCall(category, text)) {
      return ParsedNotification(
        conversationTitle: title,
        senderName: title,
        messageText: text,
        messageType: _Utils.callType(text),
      );
    }

    // Clean title
    String cleanTitle = _Utils.removeMessageCount(title);
    cleanTitle = _Utils.removeEllipsis(cleanTitle);

    bool isGroup = false;
    String senderName = cleanTitle;
    String messageText = text;

    // Try "Sender: Message" in text
    final senderMsg = _Utils.extractSenderMessage(text);
    if (senderMsg != null && senderMsg.sender != cleanTitle) {
      isGroup = true;
      senderName = senderMsg.sender;
      messageText = senderMsg.message;
    }

    return ParsedNotification(
      conversationTitle: cleanTitle,
      senderName: senderName,
      messageText: messageText,
      messageType: _Utils.detectMediaType(messageText),
      isGroup: isGroup,
    );
  }
}
