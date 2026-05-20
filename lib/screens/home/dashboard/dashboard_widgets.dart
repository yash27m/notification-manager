// lib/screens/dashboard/dashboard_widgets.dart

import 'package:flutter/material.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/database/notification_db.dart';
import 'package:notification_manager/screens/home/chat_detail/chat_detail_screen.dart';
import 'dashboard_controller.dart';
import 'app_selector_sheet.dart';

const Color primary = Color(0xFF2AAEA1);
const Color accent = Color(0xFFDBEEEB);
const Color support = Color(0xFFFCFEFF);
const Color background = Color(0xFFD5D6D8);

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: primary),
          child: Text(
            'Notification Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight(600),
            ),
          ),
        ),
        ListTile(
          title: const Text('Item 1'),
          onTap: () {
            Navigator.pop(context);
            // TODO: handle Item 1
          },
        ),
        ListTile(
          title: const Text('Item 2'),
          onTap: () {
            Navigator.pop(context);
            // TODO: handle Item 2
          },
        ),
      ],
    ),
  );
}

Widget buildAppBar(BuildContext context, DashboardController controller) {
  return ValueListenableBuilder<SelectedAppModel?>(
    valueListenable: controller.selectedApp,
    builder: (_, SelectedAppModel? app, __) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            Builder(
              builder: (innerContext) => IconButton(
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
                icon: const Icon(Icons.menu, color: Color(0xFF1A1A2E)),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                      children: [
                        TextSpan(text: 'Chats'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (app?.appName != null)
                    GestureDetector(
                      onTap: () => AppSelectorSheet.show(context, controller),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              app!.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (app?.icon != null)
              GestureDetector(
                onTap: () => AppSelectorSheet.show(context, controller),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsetsDirectional.only(start: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: accent,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(app!.icon!, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      );
    },
  );
}

Widget buildSearchBar({
  TextEditingController? controller,
  Function(String)? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              // onTapOutside: (event) {
              //   FocusManager.instance.primaryFocus?.unfocus();
              // },
              onChanged: onChanged,
              cursorColor: Colors.grey.shade400,
              // style: const TextStyle(
              //   color: Colors.white,
              //   fontSize: 14,
              // ), // Text color when typing
              decoration: InputDecoration(
                hintText: 'Search senders',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true, // Reduces vertical height to align with Row
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 11,
                ), // Centers text vertically
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    ),
  );
}

Widget buildEmptyView() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_unread_outlined,
            size: 48,
            color: primary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No messages yet!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

Widget buildConversationList(
  DashboardController controller,
  BuildContext context,
) {
  return ValueListenableBuilder<List<Conversation>>(
    // CRITICAL: Listen to the filtered list instead of the raw one
    valueListenable: controller.filteredConversations,
    builder: (_, List<Conversation> convs, __) {
      // If the filtered list is empty, decide which empty state to show
      if (convs.isEmpty) {
        final bool isSearching = controller.searchQuery.value.isNotEmpty;

        return isSearching
            ? Center(
                child: Text(
                  'No results found for "${controller.searchQuery.value}"',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              )
            : buildEmptyView();
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: convs.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
        itemBuilder: (_, int i) {
          final conversation = convs[i];
          return ConversationTile(
            conversation: conversation,
            onTap: () {
              controller.markOpened(conversation.id);
              FocusManager.instance.primaryFocus?.unfocus();
              Future.delayed(Duration(milliseconds: 150), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      conversation: conversation,
                      selectedApp: controller.selectedApp.value,
                    ),
                  ),
                );
              });
            },
          );
        },
      );
    },
  );
}
// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATION TILE
// ═══════════════════════════════════════════════════════════════════════════════

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Conversation c = conversation;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _avatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: c.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: c.unreadCount > 0
                          ? const Color(0xFF4A4A4A)
                          : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _time(c.lastTimestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: c.unreadCount > 0 ? primary : Colors.grey.shade400,
                  ),
                ),
                if (c.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (conversation.avatar != null && conversation.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: MemoryImage(conversation.avatar!),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: primary.withValues(alpha: 0.1),
      child: Text(
        conversation.title.isNotEmpty
            ? conversation.title[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }

  String _time(int ts) {
    if (ts == 0) return '';
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inDays == 0)
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)
      return const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][dt.weekday - 1];
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
