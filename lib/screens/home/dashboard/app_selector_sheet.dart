// lib/screens/dashboard/app_selector_sheet.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:notification_manager/services/installed_apps_cache.dart';
import 'dashboard_controller.dart';

class AppSelectorSheet extends StatefulWidget {
  final DashboardController controller;
  const AppSelectorSheet({super.key, required this.controller});

  static Future<void> show(
    BuildContext context,
    DashboardController controller,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppSelectorSheet(controller: controller),
    );
  }

  @override
  State<AppSelectorSheet> createState() => _AppSelectorSheetState();
}

class _AppSelectorSheetState extends State<AppSelectorSheet> {
  static const Color _primary = Color(0xFF2AAEA1);
  static const Color _accent = Color(0xFFDBEEEB);
  static const _background = Color(0xFFD5D6D8);

  bool _isManaging = false;
  List<_SheetApp> _items = [];
  bool _loading = false;

  // ── Select All ───────────────────────────────────────────────────────────
  bool get _isAllSelected =>
      _items.isNotEmpty && _items.every((a) => a.isSelected);

  void _toggleAll() {
    final bool allSelected = _isAllSelected;
    for (final app in _items) {
      app.isSelected = !allSelected;
    }
    _onSearch(); // re-apply current filter so UI updates
  }

  // ── Search (new) ───────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<_SheetApp> _filteredItems = [];

  void _onSearch() {
    final String query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_items);
      } else {
        _filteredItems = _items
            .where((a) => a.appName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  /// Clears search and resets _filteredItems to match _items.
  /// Called whenever _items changes so the two stay in sync.
  void _syncFilter() {
    _searchController.clear();
    _filteredItems = List.from(_items);
  }
  // ── End search ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadSelected();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Original methods — unchanged except _syncFilter() call added ───────────

  void _loadSelected() {
    final List<SelectedAppModel> apps = widget.controller.selectedApps.value;
    _items = apps
        .map(
          (a) => _SheetApp(
            packageName: a.packageName,
            appName: a.appName,
            icon: a.icon,
            isSelected: true,
          ),
        )
        .toList();

    _items.sort((a, b) {
      final int aCount = widget.controller.getUnreadCount(a.packageName);
      final int bCount = widget.controller.getUnreadCount(b.packageName);
      final bool aHas = aCount > 0;
      final bool bHas = bCount > 0;

      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
    });

    _syncFilter(); // NEW
    setState(() {});
  }

  Future<void> _enterManage() async {
    setState(() {
      _isManaging = true;
      _loading = true;
    });

    final List<CachedApp> cached = InstalledAppsCache.instance.apps;

    final Set<String> existing = _items.map((i) => i.packageName).toSet();
    final List<_SheetApp> newApps =
        cached
            .where((a) => !existing.contains(a.packageName))
            .map(
              (a) => _SheetApp(
                packageName: a.packageName,
                appName: a.appName,
                icon: a.icon,
                isSelected: false,
              ),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
          );

    setState(() {
      _items.addAll(newApps);
      _loading = false;
    });

    _syncFilter(); // NEW
  }

  Future<void> _done() async {
    final List<_SheetApp> selected = _items.where((i) => i.isSelected).toList();
    final List<SelectedAppModel> models = selected
        .map(
          (i) => SelectedAppModel(
            packageName: i.packageName,
            appName: i.appName,
            icon: i.icon,
          ),
        )
        .toList();

    await widget.controller.updateSelectedApps(models);
    setState(() {
      _isManaging = false;
      _items = _items.where((i) => i.isSelected).toList();
    });

    _syncFilter(); // NEW
  }

  // ── Build — only change: ListView uses _filteredItems, empty state added ───

  @override
  Widget build(BuildContext context) {
    final double minMaxH = MediaQuery.of(context).size.height * 0.7;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      constraints: BoxConstraints(minHeight: minMaxH, maxHeight: minMaxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
          // Header — unchanged
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  _isManaging ? 'Choose apps' : 'Select app',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final List<_SheetApp> selected = _items
                        .where((i) => i.isSelected)
                        .toList();

                    return GestureDetector(
                      onTap: _isManaging
                          ? (selected.isNotEmpty ? _done : null)
                          : _enterManage,
                      child: Text(
                        _isManaging ? 'Done' : 'Manage',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _isManaging
                              ? (selected.isNotEmpty
                                    ? _primary
                                    : _primary.withValues(alpha: 0.5))
                              : _primary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Search bar — NEW
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (_, value, __) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: _searchController.clear,
                            child: Icon(
                              Icons.close,
                              color: Colors.grey.shade400,
                              size: 18,
                            ),
                          );
                        },
                      ),
                      filled: true,
                      fillColor: _background.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_isManaging) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _toggleAll()),
                    child: Row(
                      children: [
                        Text(
                          'All',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAllSelected
                                ? _primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _isAllSelected
                                  ? _primary
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: _isAllSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // List — itemCount and itemBuilder now use _filteredItems
          Flexible(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                : _filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No apps found',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredItems.length, // was _items.length
                    itemBuilder: (_, i) => _tile(i),
                  ),
          ),
        ],
      ),
    );
  }

  // _tile — unchanged except reads from _filteredItems instead of _items
  Widget _tile(int index) {
    final _SheetApp item = _filteredItems[index]; // was _items[index]
    final bool isCurrent =
        item.packageName == widget.controller.selectedApp.value?.packageName;

    return InkWell(
      onTap: () {
        if (_isManaging) {
          setState(() => item.isSelected = !item.isSelected);
        } else {
          final SelectedAppModel model = SelectedAppModel(
            packageName: item.packageName,
            appName: item.appName,
            icon: item.icon,
          );
          widget.controller.switchApp(model);
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isCurrent && !_isManaging
            ? _primary.withValues(alpha: 0.08)
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _accent.withValues(alpha: 0.3),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.icon != null
                  ? Image.memory(item.icon!, fit: BoxFit.cover)
                  : const Icon(Icons.apps, color: _primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.appName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent && !_isManaging
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isManaging) _badge(item.packageName),
                ],
              ),
            ),
            if (_isManaging)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isSelected ? _primary : Colors.transparent,
                  border: Border.all(
                    color: item.isSelected ? _primary : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: item.isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Icon(Icons.add, size: 15, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }

  // _badge — unchanged
  Widget _badge(String packageName) {
    final int count = widget.controller.getUnreadCount(packageName);
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SheetApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  bool isSelected;
  _SheetApp({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isSelected = false,
  });
}
