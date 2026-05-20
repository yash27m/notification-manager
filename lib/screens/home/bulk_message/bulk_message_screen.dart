import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_manager/screens/home/dashboard/dashboard_widgets.dart';
import 'bulk_message_controller.dart';

class BulkMessageScreen extends StatefulWidget {
  /// Optional callback so a parent tab can also receive the text.
  final void Function(String text)? onSendToSearch;

  const BulkMessageScreen({super.key, this.onSendToSearch});

  @override
  State<BulkMessageScreen> createState() => _BulkMessageScreenState();
}

class _BulkMessageScreenState extends State<BulkMessageScreen>
    with SingleTickerProviderStateMixin {
  final BulkMessageController _controller = BulkMessageController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _customInputController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // ── Theme ─────────────────────────────────────────────────────

  static const _bg = Color(0xFFF5F7FA);
  static const _surface = Color(0xFFFFFFFF);
  static const _card = Color(0xFFFFFFFF);
  // static const primary = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE8F8F3);
  static const _textPrimary = Color(0xFF111827);
  static const _textMuted = Color(0xFF9CA3AF);
  static const _border = Color(0xFFE5E7EB);
  static const _danger = Color(0xFFEF4444);
  static const _whatsapp = Color(0xFF25D366);

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Keep custom text field in sync with +/- buttons
    _customInputController.text = _controller.custom.value.toString();
    _controller.custom.addListener(() {
      final val = _controller.custom.value.toString();
      if (_customInputController.text != val) {
        _customInputController.text = val;
        _customInputController.selection = TextSelection.collapsed(
          offset: val.length,
        );
      }
    });

    // Keep message text field in sync when clearAll() is called
    _controller.message.addListener(() {
      if (_controller.message.value.isEmpty &&
          _textController.text.isNotEmpty) {
        _textController.clear();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _customInputController.dispose();
    _messageFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────

  void _dismissKeyboard() {
    _messageFocus.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _onClear() {
    _controller.clearAll(); // resets message + preview, keeps counters intact
    // _textController is synced via the message listener above
  }

  Future<void> _onSendToWhatsApp() async {
    final text = _controller.joinedOutput;
    if (text.isEmpty) return;

    // Notify parent tab if wired up
    widget.onSendToSearch?.call(text);

    final success = await _controller.sendToWhatsApp();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('WhatsApp is not installed on this device.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      _controller.clearAll();
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildMessageField(),
                      const SizedBox(height: 24),
                      _buildPresetsSection(),
                      const SizedBox(height: 18),
                      _buildCustomCounter(),
                      const SizedBox(height: 24),
                      _buildGenerateButton(),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.hasGenerated,
                        builder: (_, generated, __) {
                          if (!generated) return const SizedBox.shrink();
                          return Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildOutputPreview(),
                              const SizedBox(height: 14),
                              _buildActionRow(),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.repeat_rounded, color: primary, size: 17),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Text Multiplier',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Repeat any message instantly',
                style: TextStyle(color: _textMuted, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Badge showing current repeat count
          ValueListenableBuilder<List<String>>(
            valueListenable: _controller.output,
            builder: (_, list, __) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Text(
                  '×${list.length}',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Message Field ─────────────────────────────────────────────

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('MESSAGE', Icons.edit_rounded),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _textController,
            focusNode: _messageFocus,
            textCapitalization: TextCapitalization.sentences,
            onChanged: _controller.setMessage,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _dismissKeyboard(),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: TextStyle(
                color: _textMuted.withOpacity(0.8),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── Presets ───────────────────────────────────────────────────

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('QUICK PRESETS', Icons.flash_on_rounded),
        const SizedBox(height: 8),
        ValueListenableBuilder<MultiplierMode>(
          valueListenable: _controller.mode,
          builder: (_, mode, __) {
            return ValueListenableBuilder<int>(
              valueListenable: _controller.preset,
              builder: (_, presetVal, __) {
                return Row(
                  children: [10, 100, 500, 1000].map((n) {
                    final active =
                        mode == MultiplierMode.preset && presetVal == n;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _controller.selectPreset(n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: active ? primary : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? primary : _border,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: primary.withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                n >= 1000 ? '1K' : '×$n',
                                style: TextStyle(
                                  color: active ? Colors.white : _textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── Custom Counter ────────────────────────────────────────────

  Widget _buildCustomCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('CUSTOM AMOUNT', Icons.tune_rounded),
        const SizedBox(height: 8),
        ValueListenableBuilder<MultiplierMode>(
          valueListenable: _controller.mode,
          builder: (_, mode, __) {
            final isCustom = mode == MultiplierMode.custom;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCustom ? primary : _border,
                  width: isCustom ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Repeat',
                    style: TextStyle(
                      color: isCustom ? _textPrimary : _textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _customInputController,
                      onChanged: _controller.updateCustomValue,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCustom ? primary : _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Generate Button ───────────────────────────────────────────

  Widget _buildGenerateButton() {
    return ValueListenableBuilder<String>(
      valueListenable: _controller.message,
      builder: (_, msg, __) {
        final enabled = msg.trim().isNotEmpty;
        return GestureDetector(
          onTap: enabled
              ? () {
                  _dismissKeyboard();
                  _controller.applyChanges();
                }
              : null,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: enabled ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        colors: [primary, Color.fromARGB(255, 8, 226, 205)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: enabled ? null : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: enabled ? Colors.white : _textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generate',
                    style: TextStyle(
                      color: enabled ? Colors.white : _textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Output Preview ────────────────────────────────────────────

  Widget _buildOutputPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('PREVIEW', Icons.visibility_rounded),
            const Spacer(),

            ValueListenableBuilder<List<String>>(
              valueListenable: _controller.output,
              builder: (_, list, __) {
                return Row(
                  children: [
                    const SizedBox(width: 8),

                    // 🔹 Lines Count AFTER
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${list.length} lines',
                        style: const TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final text = _controller.joinedOutput;

            if (text.isEmpty) return;

            await _controller.copyToClipboard();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text("Successfully copied to clipboard"),
                    ],
                  ),
                  backgroundColor: primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: Column(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _controller.output,
                  builder: (_, list, __) {
                    final displayCount = list.length > 1000
                        ? 1000
                        : list.length;
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayCount,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${i + 1}  ',
                                style: TextStyle(
                                  color: _textMuted.withOpacity(0.6),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              TextSpan(
                                text: list[i],
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<List<String>>(
                valueListenable: _controller.output,
                builder: (_, list, __) {
                  if (list.length <= 100) return const SizedBox.shrink();
                  return Text(
                    'Showing first 1000 of ${list.length} lines',
                    style: const TextStyle(color: _textMuted, fontSize: 11),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Action Row ────────────────────────────────────────────────

  Widget _buildActionRow() {
    return Row(
      children: [
        // ── Clear ──────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: _onClear,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _danger.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, color: _danger, size: 17),
                  SizedBox(width: 6),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── Send to WhatsApp ───────────────────────────────────
        Expanded(
          flex: 2,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: _controller.output,
            builder: (_, list, __) {
              final joined = list.join('\n');
              final isEnabled = joined.isNotEmpty && joined.length <= 8000;
              return GestureDetector(
                onTap: isEnabled ? _onSendToWhatsApp : null,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? _whatsapp.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEnabled
                          ? _whatsapp.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: isEnabled ? _whatsapp : Colors.grey,
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Send to WhatsApp',
                        style: TextStyle(
                          color: isEnabled ? _whatsapp : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Shared label widget ───────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
