import 'package:flutter/material.dart';
import 'permission_controller.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  final _controller = PermissionController();

  static const _primary = Color(0xFF2AAEA1);
  static const _gradientEnd = Color(0xFF2FC0B1);
  static const _accent = Color(0xFFDBEEEB);
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
    return Scaffold(
      backgroundColor: _support,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            // ── Info bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              color: _accent.withValues(alpha: 0.4),
              child: const Text(
                'Please enable these permissions for the app to function properly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7B8D),
                  height: 1.4,
                ),
              ),
            ),

            Expanded(child: _buildPermissionList()),

            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: ValueListenableBuilder<List<PermissionItem>>(
        valueListenable: _controller.permissions,
        builder: (_, perms, __) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_controller.grantedCount} of ${perms.length} enabled',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionList() {
    return ValueListenableBuilder<List<PermissionItem>>(
      valueListenable: _controller.permissions,
      builder: (_, perms, __) {
        if (perms.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          itemCount: perms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) => _buildPermissionCard(perms[index], index),
        );
      },
    );
  }

  Widget _buildPermissionCard(PermissionItem item, int index) {
    final granted = item.isGranted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted
              ? _primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Icon ──
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: granted
                      ? _primary.withValues(alpha: 0.1)
                      : _accent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: granted ? _primary : const Color(0xFF6B7B8D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // ── Title ──
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),

              // ── Allow / Allowed ──
              GestureDetector(
                onTap: granted ? null : () => _controller.onAllowTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: granted
                        ? null
                        : const LinearGradient(
                            colors: [_primary, _gradientEnd],
                          ),
                    color: granted ? _primary.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: granted
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 15, color: _primary),
                            SizedBox(width: 4),
                            Text(
                              'Allowed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Allow',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.allGranted,
      builder: (_, enabled, __) {
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
                    ? () async {
                        await _controller.onContinue(context);
                      }
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
                child: const Text('Continue'),
              ),
            ),
          ),
        );
      },
    );
  }
}
