import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notification_manager/screens/home/dialer/dialer_tab_contoller.dart';
import 'package:notification_manager/screens/home/dialer/widget/circle_action_button.dart';
import 'package:notification_manager/screens/home/dialer/widget/dial_button.dart';
import 'package:notification_manager/screens/home/dialer/widget/dialpad_bottomsheet.dart';
import 'package:flutter/services.dart'; // CRITICAL: Required for text formatting/cleaning

class DialerTab extends StatefulWidget {
  const DialerTab({super.key});

  @override
  State<DialerTab> createState() => _DialerTabState();
}

class _DialerTabState extends State<DialerTab> {
  final DialerController _controller = DialerController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _numberFocusNode = FocusNode();

  static const double _kKeypadWidth = 260;
  static const double _kCellSize = 70;
  static const Color _kPrimary = Color(0xFF2AAEA1);

  static const List<List<Map<String, String>>> _dialerMapRows = [
    [
      {'key': '1', 'letters': ''},
      {'key': '2', 'letters': 'ABC'},
      {'key': '3', 'letters': 'DEF'},
    ],
    [
      {'key': '4', 'letters': 'GHI'},
      {'key': '5', 'letters': 'JKL'},
      {'key': '6', 'letters': 'MNO'},
    ],
    [
      {'key': '7', 'letters': 'PQRS'},
      {'key': '8', 'letters': 'TUV'},
      {'key': '9', 'letters': 'WXYZ'},
    ],
    [
      {'key': '+', 'letters': ''},
      {'key': '0', 'letters': ''},
      {'key': '#', 'letters': '*'},
    ],
  ];

  @override
  void initState() {
    super.initState();
    _numberFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void dispose() {
    _numberFocusNode.dispose();
    _messageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // ── DISPLAY SECTION ───────────────────────────────────────────
              Container(
                height: 220,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Number display
                    CupertinoTextField(
                      controller: _controller.textController,
                      focusNode: _numberFocusNode,
                      showCursor: _numberFocusNode.hasFocus,
                      autofocus: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                      ],
                      cursorHeight: 30,
                      cursorColor: CupertinoColors.activeBlue.resolveFrom(
                        context,
                      ),
                      cursorWidth: 3,
                      keyboardType: TextInputType.none,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      decoration: null,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                        decoration: TextDecoration.none,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Message field
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _controller.updateMessage,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xDD090909),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Add an optional message...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 70, 69, 69),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── KEYPAD SECTION ────────────────────────────────────────────
              SizedBox(
                width: _kKeypadWidth,
                child: Column(
                  children: [
                    for (int i = 0; i < _dialerMapRows.length; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _dialerMapRows[i].map((k) {
                          return DialButton(
                            digit: k['key']!,
                            letters: k['letters']!,
                            size: _kCellSize,
                            onTap: () {
                              _numberFocusNode.requestFocus();
                              _controller.onKeyPress(k['key']!);
                            },
                            onLongPress: k['key'] == '#'
                                ? () {
                                    _numberFocusNode.requestFocus();
                                    _controller.onKeyPress('*');
                                  }
                                : null,
                          );
                        }).toList(),
                      ),
                      if (i < _dialerMapRows.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),

              // ── ACTION SECTION ────────────────────────────────────────────
              const SizedBox(height: 20),
              SizedBox(
                width: _kKeypadWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // History button
                    CircleActionButton(
                      icon: Icons.history,
                      iconColor: CupertinoColors.label.resolveFrom(context),
                      backgroundColor: const Color(0xFFE5E5EA),
                      size: _kCellSize,
                      iconSize: 28,
                      onTap: () {
                        DialHistorySheet.show(context, _controller);
                      },
                    ),
                    // Send button
                    ValueListenableBuilder<String>(
                      valueListenable: _controller.phoneNumber,
                      builder: (context, val, _) {
                        final hasValue = val.isNotEmpty;
                        return CircleActionButton(
                          icon: Icons.send_rounded,
                          iconColor: hasValue ? Colors.white : Colors.grey,
                          backgroundColor: hasValue
                              ? _kPrimary
                              : const Color(0xFFE5E5EA),
                          size: _kCellSize,
                          iconSize: 28,
                          onTap: hasValue
                              ? () async {
                                  await _controller.openWhatsApp(context);
                                  _controller.clearAll();
                                  _messageController.clear();
                                  _numberFocusNode.requestFocus();
                                }
                              : () {},
                        );
                      },
                    ),
                    // Backspace button
                    SizedBox(
                      width: _kCellSize,
                      height: _kCellSize,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _controller.phoneNumber,
                        builder: (context, val, _) {
                          if (val.isEmpty) return const SizedBox.shrink();
                          return Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _numberFocusNode.requestFocus();
                                _controller.onBackspace();
                              },
                              onLongPress: () {
                                _numberFocusNode.requestFocus();
                                _controller.clearAll();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  CupertinoIcons.delete_left,
                                  size: 30,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
