// lib/screens/dashboard/general_view.dart

import 'package:flutter/material.dart';
import 'dashboard_controller.dart';
import 'dashboard_widgets.dart';

class GeneralView extends StatelessWidget {
  final DashboardController controller;
  const GeneralView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: support,
      drawer: buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            buildAppBar(context, controller),
            buildSearchBar(),
            Expanded(child: buildConversationList(controller, context)),
          ],
        ),
      ),
    );
  }
}
