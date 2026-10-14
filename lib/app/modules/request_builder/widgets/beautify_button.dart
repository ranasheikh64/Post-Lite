import 'package:flutter/material.dart';

class BeautifyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isBeautified;

  const BeautifyButton({
    super.key,
    required this.onPressed,
    this.isBeautified = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isBeautified ? const Color(0xFF4CAF50) : const Color(0xFFFF6C37);

    return Tooltip(
      message: isBeautified
          ? 'Formatted'
          : 'Beautify / Format (Shift + Cmd/Ctrl + B)',
      child: Material(
        color: const Color(0xFF242736),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          hoverColor: activeColor.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isBeautified
                    ? activeColor.withValues(alpha: 0.5)
                    : Colors.white12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBeautified
                      ? Icons.check_rounded
                      : Icons.auto_fix_high_rounded,
                  size: 14,
                  color: activeColor,
                ),
                const SizedBox(width: 5),
                Text(
                  isBeautified ? 'Beautified' : 'Beautify',
                  style: TextStyle(
                    color: isBeautified ? activeColor : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
