// lib/screens/chat_detail/chat_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/database/notification_db.dart';
import 'chat_detail_controller.dart';

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  final String appName; // "WhatsApp", "Instagram", etc.
  final SelectedAppModel? selectedApp;
  const ChatDetailScreen({
    super.key,
    required this.conversation,
    this.appName = '',
    this.selectedApp,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late final ChatDetailController _controller;
  final ScrollController _scrollController = ScrollController();

  static const Color _primary = Color(0xFF2AAEA1);

  @override
  void initState() {
    super.initState();
    _controller = ChatDetailController(conversation: widget.conversation);
    _controller.init();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildChatArea()),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──

  Widget _buildAppBar() {
    final Conversation c = widget.conversation;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          ),
          _avatar(c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.appName.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.appName,
                    style: const TextStyle(fontSize: 12, color: _primary),
                  ),
                ],
              ],
            ),
          ),
          if (widget.selectedApp != null &&
              (widget.selectedApp?.packageName ?? '').isNotEmpty)
            IconButton(
              onPressed: () => _controller.redirectToApp(context),
              icon: Icon(
                Icons.filter_list,
                color: Colors.grey.shade700,
                size: 22,
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: Colors.grey.shade700, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Conversation c) {
    if (c.avatar != null && c.avatar!.isNotEmpty) {
      return CircleAvatar(radius: 20, backgroundImage: MemoryImage(c.avatar!));
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: _primary.withValues(alpha: 0.1),
      child: Text(
        c.title.isNotEmpty ? c.title[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _primary,
        ),
      ),
    );
  }

  // ── Chat Area ──

  Widget _buildChatArea() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/chat_background.png'),
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
      ),
      child: ValueListenableBuilder<List<ChatMessage>>(
        valueListenable: _controller.messages,
        builder: (_, List<ChatMessage> msgs, __) {
          if (msgs.isEmpty) return _emptyChat();

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: msgs.length + (_controller.hasMore ? 1 : 0),
            itemBuilder: (_, int index) {
              if (index == msgs.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    ),
                  ),
                );
              }

              final ChatMessage msg = msgs[index];
              // Previous = older message (higher index since reversed)
              final ChatMessage? olderMsg = index + 1 < msgs.length
                  ? msgs[index + 1]
                  : null;

              return _ChatBubble(
                message: msg,
                isGroup: widget.conversation.isGroup,
                showSender: _shouldShowSender(msg, olderMsg),
                showDate: _shouldShowDate(msg, olderMsg),
              );
            },
          );
        },
      ),
    );
  }

  /// Show sender name when sender changes (comparing with the older message above)
  bool _shouldShowSender(ChatMessage current, ChatMessage? older) {
    if (!widget.conversation.isGroup) return false;
    if (older == null) return true;
    return current.senderName != older.senderName;
  }

  /// Show date divider when day changes
  bool _shouldShowDate(ChatMessage current, ChatMessage? older) {
    if (older == null) return true;
    final DateTime cDt = DateTime.fromMillisecondsSinceEpoch(current.timestamp);
    final DateTime oDt = DateTime.fromMillisecondsSinceEpoch(older.timestamp);
    return cDt.day != oDt.day || cDt.month != oDt.month || cDt.year != oDt.year;
  }

  Widget _emptyChat() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: _primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT BUBBLE — all left-aligned (we only capture incoming notifications)
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isGroup;
  final bool showSender;
  final bool showDate;

  const _ChatBubble({
    required this.message,
    required this.isGroup,
    required this.showSender,
    required this.showDate,
  });

  static const Color _primary = Color(0xFF2AAEA1);

  static const List<Color> _senderColors = [
    Color(0xFF1B9C85),
    Color(0xFF6C63FF),
    Color(0xFFE17055),
    Color(0xFF00B894),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFBE76),
    Color(0xFFA29BFE),
    Color(0xFFD35400),
    Color(0xFF2980B9),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDate) _dateHeader(),
        if (showSender && isGroup) _senderLabel(),
        _bubble(),
      ],
    );
  }

  // ── Date divider ──

  Widget _dateHeader() {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          _formatDateLabel(dt),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // ── Sender name label (above bubble for groups) ──

  Widget _senderLabel() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 2),
      child: Text(
        message.senderName,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _senderColor(message.senderName),
        ),
      ),
    );
  }

  // ── Message bubble ──

  Widget _bubble() {
    final bool isDeleted = message.isRemoved;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _content(isDeleted),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2, top: 4),
                child: Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(bool isDeleted) {
    final bool hasThumbnail =
        message.thumbnail != null && message.thumbnail!.isNotEmpty;
    Widget childDetails = const SizedBox.shrink();

    switch (message.type) {
      case MessageType.image:
        childDetails = _mediaItem('📷', 'Photo', hasThumbnail);
        break;
      case MessageType.video:
        childDetails = _mediaItem('🎥', 'Video', hasThumbnail);
        break;
      case MessageType.audio:
        childDetails = _mediaItem('🎵', 'Audio', hasThumbnail);
        break;
      case MessageType.voiceNote:
        childDetails = _mediaItem('🎤', 'Voice message', hasThumbnail);
        break;
      case MessageType.document:
        childDetails = _mediaItem('📄', 'Document', hasThumbnail);
        break;
      case MessageType.sticker:
        childDetails = _mediaItem('🏷️', 'Sticker', hasThumbnail);
        break;
      case MessageType.location:
        childDetails = _mediaItem('📍', 'Location', hasThumbnail);
        break;
      case MessageType.contact:
        childDetails = _mediaItem('👤', 'Contact', hasThumbnail);
        break;
      case MessageType.call:
      case MessageType.missedCall:
        childDetails = _callRow();
        break;
      default:
        childDetails = _textItem();
        break;
    }

    Widget content;
    if (!hasThumbnail) {
      content = childDetails;
    } else {
      final bool showDetails = childDetails is! SizedBox;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Image.memory(message.thumbnail!, fit: BoxFit.cover),
            ),
          ),
          if (showDetails) const SizedBox(height: 6),
          if (showDetails) childDetails,
        ],
      );
    }

    // if (isDeleted) {
    //   return Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       content,
    //       const SizedBox(height: 4),
    //       Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Icon(Icons.info_outline, size: 12, color: Colors.red.shade300),
    //           const SizedBox(width: 4),
    //           Text(
    //             'Notification removed',
    //             style: TextStyle(
    //               fontSize: 10,
    //               fontStyle: FontStyle.italic,
    //               color: Colors.red.shade400,
    //             ),
    //           ),
    //         ],
    //       ),
    //     ],
    //   );
    // }

    return content;
  }

  Widget _mediaItem(String emoji, String label, bool hasThumbnail) {
    final bool hasCustomText =
        message.text.isNotEmpty &&
        message.text.toLowerCase() != label.toLowerCase() &&
        message.text.toLowerCase() != '$emoji $label'.toLowerCase();

    if (hasThumbnail) {
      if (!hasCustomText) return const SizedBox.shrink();
      return _textItem();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        if (hasCustomText) ...[const SizedBox(height: 4), _textItem()],
      ],
    );
  }

  Widget _textItem() {
    if (message.text.isEmpty) return const SizedBox.shrink();
    return Text(
      message.text,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A2E),
        height: 1.4,
      ),
    );
  }

  Widget _callRow() {
    final bool missed = message.type == MessageType.missedCall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          missed ? Icons.phone_missed : Icons.phone,
          size: 16,
          color: missed ? Colors.red.shade400 : _primary,
        ),
        const SizedBox(width: 6),
        Text(
          missed
              ? 'Missed call'
              : (message.text.isNotEmpty ? message.text : 'Call'),
          style: TextStyle(
            fontSize: 14,
            color: missed ? Colors.red.shade400 : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Color _senderColor(String name) {
    return _senderColors[name.hashCode.abs() % _senderColors.length];
  }

  String _formatTime(int ts) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final int h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final String amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDateLabel(DateTime dt) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diff = today
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      return const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][dt.weekday - 1];
    }
    return '${dt.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]} ${dt.year}';
  }
}
