import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_manager/database/hive_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DialerController {
  final phoneNumber = ValueNotifier<String>('');
  final message = ValueNotifier<String>('');
  final history = ValueNotifier<List<DialHistoryEntryModel>>([]);

  final TextEditingController textController = TextEditingController();
  static const int _maxPhoneLength = 15;

  DialerController() {
    _loadHistory();
    textController.addListener(() {
      phoneNumber.value = textController.text;
    });
  }

  void _loadHistory() {
    history.value = HiveService.instance.getDialHistory();
  }

  void fillFromHistory(DialHistoryEntryModel entry) {
    textController.text = entry.phoneNumber;
    message.value = entry.message;

    // Position cursor at end of number
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
  }

  Future<void> removeHistoryEntry(DialHistoryEntryModel entry) async {
    await HiveService.instance.removeDialEntry(entry);
    _loadHistory();
  }

  Future<void> clearHistory() async {
    // Uses the clearDialHistory from your service
    await HiveService.instance.clearDialHistory();
    _loadHistory();
  }

  // ── INPUT LOGIC ──────────────────────────────────────────────────────────

  void onKeyPress(String key) {
    HapticFeedback.lightImpact();
    _insertAtCursor(key);
  }

  void _insertAtCursor(String text) {
    final current = textController.text;
    var selection = textController.selection;

    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: current.length);
    }

    final newText = current.replaceRange(selection.start, selection.end, text);

    if (newText.length > _maxPhoneLength) return;
    if (text == '+' && current.contains('+')) return;

    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void onBackspace() {
    final current = textController.text;
    if (current.isEmpty) return;

    HapticFeedback.selectionClick();
    var selection = textController.selection;

    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: current.length);
    }

    if (!selection.isCollapsed) {
      final newText = current.replaceRange(selection.start, selection.end, '');
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      if (selection.start == 0) return;
      final newText = current.replaceRange(
        selection.start - 1,
        selection.start,
        '',
      );
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    }
  }

  void clearAll() {
    if (textController.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    textController.clear();
  }

  void updateMessage(String value) => message.value = value;

  // ── WHATSAPP & SAVE ──────────────────────────────────────────────────────

  Future<void> openWhatsApp(BuildContext context) async {
    final number = textController.text;
    if (number.isEmpty) return;

    final newEntry = DialHistoryEntryModel(
      phoneNumber: number,
      message: message.value,
      calledAt: DateTime.now(),
    );

    await HiveService.instance.addDialEntry(newEntry);
    _loadHistory();

    // 3. Launch WhatsApp
    final uri = Uri.parse(
      "https://wa.me/${number.replaceAll('+', '')}?text=${Uri.encodeComponent(message.value)}",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void dispose() {
    textController.dispose();
    phoneNumber.dispose();
    message.dispose();
    history.dispose();
  }
}
