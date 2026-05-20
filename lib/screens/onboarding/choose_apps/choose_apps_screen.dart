import 'package:flutter/material.dart';
import 'choose_apps_controller.dart';

class ChooseAppsScreen extends StatefulWidget {
  const ChooseAppsScreen({super.key});

  @override
  State<ChooseAppsScreen> createState() => _ChooseAppsScreenState();
}

class _ChooseAppsScreenState extends State<ChooseAppsScreen>
    with WidgetsBindingObserver {
  final _controller = ChooseAppsController();

  static const _primary = Color(0xFF2AAEA1);
  static const _gradientEnd = Color(0xFF2FC0B1);
  static const _accent = Color(0xFFDBEEEB);
  static const _background = Color(0xFFD5D6D8);
  static const _support = Color(0xFFFCFEFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _support,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                color: _accent.withValues(alpha: 0.4),
                child: const Text(
                  "Selected apps' notifications will be saved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7B8D),
                    height: 1.4,
                  ),
                ),
              ),

              _buildSearch(),

              Expanded(child: _buildAppList()),

              // ── WhatsApp access cards ──
              _buildWhatsAppAccessSection(),

              // ── Confirm button ──
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose apps',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<int>(
                  valueListenable: _controller.selectedCount,
                  builder: (_, count, __) {
                    return ValueListenableBuilder(
                      valueListenable: _controller.allApps,
                      builder: (_, apps, __) {
                        return Text(
                          '$count of ${apps.length} selected',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                'All',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: _controller.selectedCount,
                builder: (_, __, ___) {
                  return GestureDetector(
                    onTap: _controller.toggleAll,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _controller.isAllSelected ? _primary : Colors.transparent,
                        border: Border.all(
                          color: _controller.isAllSelected ? _primary : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: _controller.isAllSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: TextField(
        controller: _controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          filled: true,
          fillColor: _background.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAppList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isLoading,
      builder: (_, loading, __) {
        if (loading) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        return ValueListenableBuilder<List<AppItem>>(
          valueListenable: _controller.filteredApps,
          builder: (_, apps, __) {
            if (apps.isEmpty) {
              return Center(
                child: Text(
                  'No apps found',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, index) => _buildAppTile(apps[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildAppTile(AppItem app, int index) {
    return InkWell(
      onTap: () => _controller.toggleApp(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _accent.withValues(alpha: 0.3),
              ),
              clipBehavior: Clip.antiAlias,
              child: app.icon != null
                  ? Image.memory(app.icon!, fit: BoxFit.cover)
                  : const Icon(Icons.apps, color: _primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                app.appName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: app.isSelected ? _primary : Colors.transparent,
                border: Border.all(
                  color: app.isSelected ? _primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: app.isSelected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : Icon(Icons.add, size: 15, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // ── WhatsApp Access Section ──

  Widget _buildWhatsAppAccessSection() {
    return ValueListenableBuilder<List<WhatsAppAccess>>(
      valueListenable: _controller.whatsappAccessList,
      builder: (_, list, __) {
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((wa) => _buildWhatsAppAccessCard(wa)).toList(),
        );
      },
    );
  }

  Widget _buildWhatsAppAccessCard(WhatsAppAccess wa) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: wa.hasAccess ? _accent.withValues(alpha: 0.3) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: wa.hasAccess ? _primary.withValues(alpha: 0.3) : const Color(0xFFFFD6D6),
        ),
      ),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: wa.hasAccess
                  ? _primary.withValues(alpha: 0.1)
                  : const Color(0xFFFFE0E0),
            ),
            clipBehavior: Clip.antiAlias,
            child: wa.icon != null
                ? Image.memory(wa.icon!, fit: BoxFit.cover)
                : Icon(
                    Icons.warning_amber_rounded,
                    color: wa.hasAccess ? _primary : const Color(0xFFE57373),
                    size: 20,
                  ),
          ),

          const SizedBox(width: 12),

          // ── Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wa.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wa.hasAccess
                      ? 'Folder access granted'
                      : 'Allow to backup photos, audio, video, etc...',
                  style: TextStyle(
                    fontSize: 12,
                    color: wa.hasAccess ? _primary : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Allow / Granted ──
          GestureDetector(
            onTap: wa.hasAccess
                ? null
                : () => _controller.requestWhatsAppAccess(wa.packageName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: wa.hasAccess
                    ? null
                    : const LinearGradient(colors: [_primary, _gradientEnd]),
                color: wa.hasAccess ? _primary.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: wa.hasAccess
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: _primary),
                        SizedBox(width: 4),
                        Text(
                          'Granted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Allow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm Button ──

  Widget _buildConfirmButton() {
    return ValueListenableBuilder<int>(
      valueListenable: _controller.selectedCount,
      builder: (_, count, __) {
        final enabled = count > 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: enabled
                      ? [_primary, _gradientEnd]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: enabled
                    ? () async => await _controller.confirmSelection(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continue Setup'),
              ),
            ),
          ),
        );
      },
    );
  }
}