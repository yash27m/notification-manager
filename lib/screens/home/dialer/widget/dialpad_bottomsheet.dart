import 'package:flutter/material.dart';
import 'package:notification_manager/screens/home/dialer/dialer_tab_contoller.dart';
import 'package:notification_manager/database/hive_service.dart';

class DialHistorySheet extends StatelessWidget {
  final DialerController controller;
  const DialHistorySheet({super.key, required this.controller});

  static const Color _primary = Color(0xFF2AAEA1);

  static Future<void> show(BuildContext context, DialerController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DialHistorySheet(controller: controller),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.65;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      // ✅ ValueNotifier handles updates
      child: ValueListenableBuilder<List<DialHistoryEntryModel>>(
        valueListenable: controller.history,
        builder: (context, history, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── HANDLE ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── HEADER ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Dial history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),

                    if (history.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          await controller.clearHistory(); // ✅ no pop
                        },
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.5),

              // ── LIST ──
              Flexible(
                child: history.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: history.length,
                        itemBuilder: (_, i) {
                          final item = history[i];

                          return _HistoryTile(
                            entry: item,
                            timeLabel: _formatTime(item.calledAt),

                            // Fill data back to dialer
                            onTap: () {
                              controller.fillFromHistory(item);
                              Navigator.pop(context);
                            },

                            // Delete item
                            onDismissed: () {
                              controller.removeHistoryEntry(item);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 44, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No recent dials',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Numbers you send will appear here',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DialHistoryEntryModel entry;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _HistoryTile({
    required this.entry,
    required this.timeLabel,
    required this.onTap,
    required this.onDismissed,
  });

  static const Color _primary = Color(0xFF2AAEA1);
  static const Color _accent = Color(0xFFE1F5EE);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade50,
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),

      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_outlined, color: _primary),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.phoneNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (entry.message.isNotEmpty)
                      Text(
                        entry.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                    Text(
                      timeLabel,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
