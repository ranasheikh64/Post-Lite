import 'package:flutter/material.dart';

PopupMenuItem<String?> buildWorkspaceMenuItem({
  required String? id,
  required String title,
  required IconData icon,
  required bool isSelected,
}) {
  return PopupMenuItem<String?>(
    value: id,
    height: 36,
    child: Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isSelected ? const Color(0xFFFF6C37) : Colors.white70,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFFFF6C37) : Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected)
          const Icon(Icons.check, size: 16, color: Color(0xFFFF6C37)),
      ],
    ),
  );
}
