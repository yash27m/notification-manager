import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum MultiplierMode { preset, custom }

class BulkMessageController {
  // ── State ─────────────────────────────────────────────────────

  final ValueNotifier<String> message = ValueNotifier<String>('');
  final ValueNotifier<int> preset = ValueNotifier<int>(10);
  final ValueNotifier<int> custom = ValueNotifier<int>(10);
  final ValueNotifier<MultiplierMode> mode = ValueNotifier<MultiplierMode>(
    MultiplierMode.preset,
  );
  final ValueNotifier<List<String>> output = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> hasGenerated = ValueNotifier<bool>(false);

  // ── Getters ───────────────────────────────────────────────────

  int get currentMultiplier =>
      mode.value == MultiplierMode.preset ? preset.value : custom.value;

  bool get isReady => message.value.trim().isNotEmpty;

  /// Newline-joined output ready to send to WhatsApp
  String get joinedOutput => output.value.join('\n');

  // ── Message ───────────────────────────────────────────────────

  void setMessage(String value) {
    message.value = value;
    _clearPreview(); // always clear on any change
  }

  // ── Presets ───────────────────────────────────────────────────

  void selectPreset(int value) {
    preset.value = value;
    custom.value = value;
    mode.value = MultiplierMode.preset;
    _clearPreview(); // clear so user must re-generate
  }

  // ── Copy ───────────────────────────────────────────────────
  Future<void> copyToClipboard() async {
    final text = joinedOutput;
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
  }
  // ── Custom counter ────────────────────────────────────────────

  void incrementCustom() {
    custom.value++;
    mode.value = MultiplierMode.custom;
  }

  void decrementCustom() {
    if (custom.value > 1) {
      custom.value--;
      mode.value = MultiplierMode.custom;
    }
  }

  void updateCustomValue(String value) {
    if (value.isEmpty) {
      custom.value = 1;
      mode.value = MultiplierMode.custom;
      _clearPreview();
      return;
    }

    final parsed = int.tryParse(value);

    if (parsed != null && parsed >= 1) {
      custom.value = parsed;

      if ([10, 100, 500, 1000].contains(parsed)) {
        preset.value = parsed;
        mode.value = MultiplierMode.preset;
      } else {
        mode.value = MultiplierMode.custom;
      }
    }
  }

  // ── Generate ──────────────────────────────────────────────────

  void applyChanges() {
    if (!isReady || currentMultiplier <= 0) return;

    output.value = List.generate(
      currentMultiplier,
      (_) => message.value.trim(),
    );

    hasGenerated.value = true;
  }

  // ── Clear ─────────────────────────────────────────────────────

  void clearAll() {
    message.value = '';

    // ✅ Reset counters
    preset.value = 10;
    custom.value = 10;
    mode.value = MultiplierMode.preset;

    _clearPreview();
  }

  void _clearPreview() {
    output.value = [];
    hasGenerated.value = false;
  }

  // ── WhatsApp ──────────────────────────────────────────────────

  /// Returns true on success, false if WhatsApp is not available.
  Future<bool> sendToWhatsApp() async {
    final text = joinedOutput;
    if (text.isEmpty) return false;

    final encoded = Uri.encodeComponent(text);
    if (encoded.length > 8000) return false;

    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // ── Cleanup ───────────────────────────────────────────────────

  void dispose() {
    message.dispose();
    preset.dispose();
    custom.dispose();
    mode.dispose();
    output.dispose();
    hasGenerated.dispose();
  }
}
