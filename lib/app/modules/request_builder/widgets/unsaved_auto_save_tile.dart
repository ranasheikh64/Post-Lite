import 'package:flutter/material.dart';

class UnsavedAutoSaveTile extends StatelessWidget {
  final bool autoSave;
  final ValueChanged<bool> onChanged;

  const UnsavedAutoSaveTile({
    super.key,
    required this.autoSave,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, size: 15, color: Color(0xFFFF6C37)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Always auto-save on close (don\'t ask again)',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: autoSave,
              activeThumbColor: const Color(0xFFFF6C37),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
