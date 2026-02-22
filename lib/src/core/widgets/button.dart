import 'package:flutter/widgets.dart';

class RawButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final Color color;

  const RawButton({
    super.key,
    required this.onTap,
    required this.label,
    this.color = const Color(0xFF007AFF),
  });

  @override
  State<RawButton> createState() => _RawButtonState();
}

class _RawButtonState extends State<RawButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color textColor = switch (widget.color.computeLuminance()) {
      > 0.5 => const Color(0xFF000000),
      _ => const Color(0xFFFFFFFF),
    };

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Opacity(
        opacity: _isPressed ? 0.8 : 1.0,
        child: Transform.scale(
          scale: _isPressed ? 0.98 : 1.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
