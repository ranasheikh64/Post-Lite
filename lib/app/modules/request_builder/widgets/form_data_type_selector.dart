import 'package:flutter/material.dart';

class FormDataTypeSelector extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onTypeChanged;

  const FormDataTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  bool get isFile => currentType == 'file';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Select type (Text / File)',
      color: const Color(0xFF222536),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF2E334D)),
      ),
      offset: const Offset(0, 24),
      onSelected: onTypeChanged,
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'text',
          height: 30,
          child: Row(
            children: [
              Icon(Icons.text_fields_rounded, size: 14, color: Colors.white70),
              SizedBox(width: 8),
              Text('Text', style: TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'file',
          height: 30,
          child: Row(
            children: [
              Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFFFF6C37)),
              SizedBox(width: 8),
              Text('File', style: TextStyle(fontSize: 12, color: Color(0xFFFF6C37))),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isFile ? const Color(0x33FF6C37) : const Color(0xFF24283B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isFile ? const Color(0xFFFF6C37) : const Color(0xFF333852),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFile ? 'File' : 'Text',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isFile ? const Color(0xFFFF6C37) : const Color(0xFF8E92A8),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 12,
              color: isFile ? const Color(0xFFFF6C37) : const Color(0xFF8E92A8),
            ),
          ],
        ),
      ),
    );
  }
}
