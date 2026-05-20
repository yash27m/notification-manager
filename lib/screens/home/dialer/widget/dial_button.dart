import 'package:flutter/material.dart';

class DialButton extends StatefulWidget {
  const DialButton({
    super.key,
    required this.digit,
    this.letters = '',
    required this.onTap,
    this.onLongPress,
    this.size = 70, // default size iOS like
  });

  final String digit;
  final String letters;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;

  @override
  State<DialButton> createState() => _DialButtonState();
}

class _DialButtonState extends State<DialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? const Color(0xFFD1D1D6) // Native iOS pressed gray
              : const Color(0xFFE5E5EA), // Native iOS default gray
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.digit,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w400,
                height: 1.0,
                decoration: TextDecoration.none,
                color: Colors.black,
              ),
            ),
            if (widget.letters.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                widget.letters,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700, // Make it very bold like iOS
                  letterSpacing: 2.0,
                  height: 1.0,
                  decoration: TextDecoration.none,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
