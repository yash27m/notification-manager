// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'dashboard_controller.dart';
import 'dashboard_widgets.dart';
import 'general_view.dart';
import 'whatsapp/whatsapp_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SelectedAppModel?>(
      valueListenable: _controller.selectedApp,
      builder: (_, SelectedAppModel? app, __) {
        if (app == null) return _emptyScaffold('No apps selected');
        return _controller.isWhatsApp
            ? WhatsAppView(controller: _controller)
            : GeneralView(controller: _controller);
      },
    );
  }

  Widget _emptyScaffold(String msg) {
    return Scaffold(
      backgroundColor: support,
      body: Center(
        child: Text(msg, style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }
}
