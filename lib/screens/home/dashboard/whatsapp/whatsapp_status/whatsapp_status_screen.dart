import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_manager/screens/home/dashboard/dashboard_widgets.dart';
import 'package:notification_manager/screens/home/dashboard/whatsapp/whatsapp_status/whatsapp_status_controller.dart';

// Height of the floating tab bar — used as top padding in the grid so the
// first row starts below it on initial load.
const double _kTabBarHeight = 70.0;

class WhatsAppStatusScreen extends StatefulWidget {
  const WhatsAppStatusScreen({super.key});

  @override
  State<WhatsAppStatusScreen> createState() => _WhatsAppStatusScreenState();
}

class _WhatsAppStatusScreenState extends State<WhatsAppStatusScreen>
    with SingleTickerProviderStateMixin {
  late WhatsAppStatusController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WhatsAppStatusController(context: context, vsync: this);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Full-height tab content ──────────────────────────────────
            TabBarView(
              controller: _controller.tabController,
              dragStartBehavior: DragStartBehavior.down,
              children: [
                ValueListenableBuilder2(
                  first: _controller.isLoadingNotifier,
                  second: _controller.recentItemsNotifier,
                  builder: (context, isLoading, recentItems, _) {
                    return _buildGrid(
                      recentItems,
                      isSaved: false,
                      isLoading: isLoading,
                    );
                  },
                ),
                ValueListenableBuilder2(
                  first: _controller.isLoadingNotifier,
                  second: _controller.savedItemsNotifier,
                  builder: (context, isLoading, savedItems, _) {
                    return _buildGrid(
                      savedItems,
                      isSaved: true,
                      isLoading: isLoading,
                    );
                  },
                ),
              ],
            ),

            // ── Floating tab bar on top ──────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder2(
                first: _controller.recentItemsNotifier,
                second: _controller.savedItemsNotifier,
                builder: (context, recentItems, savedItems, _) {
                  return _WhatsAppTabHeader(
                    tabController: _controller.tabController,
                    recentCount: recentItems.length,
                    savedCount: savedItems.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<StatusItem> items, {
    required bool isSaved,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: primary));
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          // top padding so empty state isn't hidden behind the tab bar
          padding: const EdgeInsets.fromLTRB(32, _kTabBarHeight + 16, 32, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSaved
                      ? Icons.download_done_rounded
                      : Icons.image_search_rounded,
                  color: primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String?>(
                valueListenable: _controller.errorMessageNotifier,
                builder: (context, errorMessage, _) {
                  return Text(
                    isSaved
                        ? "No saved statuses yet."
                        : (errorMessage ?? "No statuses found."),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  );
                },
              ),
              if (!isSaved) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _controller.fetchStatuses,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      backgroundColor: Colors.white,
      onRefresh: _controller.fetchStatuses,
      child: GridView.builder(
        // top padding = tab bar height so first row starts below it;
        // as the user scrolls up, content slides behind the frosted bar
        padding: const EdgeInsets.fromLTRB(12, _kTabBarHeight, 12, 12),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => _controller.openPreview(item, items),
            onLongPress: () {
              _controller.saveStatus(item);
              HapticFeedback.heavyImpact();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.isVideo
                      ? Container(
                          color: const Color(0xFF0D1B2A),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: primary,
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      : Image.file(
                          item.file,
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                          filterQuality: FilterQuality.low,
                        ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (item.isVideo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              color: primary,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: isSaved
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              "Saved",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _controller.saveStatus(item),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating tab header — frosted glass look via BackdropFilter
// ─────────────────────────────────────────────────────────────────────────────

const Color _kGreenDark = Color(0xFF128C7E);

class _WhatsAppTabHeader extends StatelessWidget {
  const _WhatsAppTabHeader({
    required this.tabController,
    required this.recentCount,
    required this.savedCount,
  });

  final TabController tabController;
  final int recentCount;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    // ClipRect + BackdropFilter gives the frosted-glass effect so content
    // scrolling behind it is blurred rather than just covered.
    return ClipRect(
      child: BackdropFilter(
        filter: const ColorFilter.matrix(<double>[
          // identity — actual blur is handled by ImageFilter below
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: _buildBar(context),
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // semi-transparent white so content shows through
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [primary, _kGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF6B7280),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              _TabItem(
                icon: Icons.access_time_rounded,
                label: "Recent",
                count: recentCount,
              ),
              _TabItem(
                icon: Icons.download_done_rounded,
                label: "Saved",
                count: savedCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey(count),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}
