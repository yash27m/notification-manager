import 'package:flutter/cupertino.dart';

class CircleActionButton extends StatefulWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.iconColor = CupertinoColors.white,
    this.size = 65,
    this.iconSize = 30,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  @override
  State<CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<CircleActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundColor,
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }
}
