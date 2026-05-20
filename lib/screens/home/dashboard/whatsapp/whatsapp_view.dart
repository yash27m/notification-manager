// lib/screens/dashboard/whatsapp_view.dart

import 'package:flutter/material.dart';
import 'package:notification_manager/screens/home/dashboard/font_styles/font_style_screen.dart';
import 'package:notification_manager/screens/home/dashboard/whatsapp/whatsapp_status/whatsapp_status_screen.dart';
import '../dashboard_controller.dart';
import '../dashboard_widgets.dart';
import 'package:notification_manager/screens/home/bulk_message/bulk_message_screen.dart';
import 'package:notification_manager/screens/home/dialer/dialer_tab_screen.dart';

class WhatsAppView extends StatefulWidget {
  final DashboardController controller;
  const WhatsAppView({super.key, required this.controller});

  @override
  State<WhatsAppView> createState() => _WhatsAppViewState();
}

class _WhatsAppViewState extends State<WhatsAppView> {
  int _tab = 0;

  static const List<String> _labels = [
    'Message',
    'Status',
    'Dialer',
    'Bulk Message',
    'Fonts',
  ];
  static const List<IconData> _icons = [
    Icons.chat_bubble_rounded,
    Icons.check_circle_outline_rounded,
    Icons.phone_rounded,
    Icons.mail_rounded,
    Icons.text_fields_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: support,
        drawer: buildDrawer(context),
        resizeToAvoidBottomInset: !(_tab == 2),
        body: SafeArea(
          child: Column(
            children: [
              buildAppBar(context, widget.controller),
              Expanded(
                child: _tab == 0
                    ? _messageTab(widget.controller)
                    : _tab == 1
                    ? WhatsAppStatusScreen()
                    : _tab == 2
                    ? DialerTab()
                    : _tab == 3
                    ? BulkMessageScreen()
                    : FontStyleGenerator(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomNav(),
      ),
    );
  }

  Widget _messageTab(DashboardController controller) {
    return Column(
      children: [
        buildSearchBar(onChanged: (value) => controller.onSearchChanged(value)),
        Expanded(child: buildConversationList(widget.controller, context)),
      ],
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_labels.length, (int i) {
              final bool active = i == _tab;
              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[i],
                      color: active ? primary : Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? primary : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
