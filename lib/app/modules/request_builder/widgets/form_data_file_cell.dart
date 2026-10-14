import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FormDataFileCell extends StatelessWidget {
  final String filePath;
  final ValueChanged<String> onFileSelected;

  const FormDataFileCell({
    super.key,
    required this.filePath,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            filePath.isNotEmpty ? filePath.split('/').last : 'Select file',
            style: TextStyle(
              color: filePath.isNotEmpty ? Colors.white : const Color(0xFF6B7280),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.file_upload, size: 14, color: Color(0xFFFF6C37)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () async {
            final r = await FilePicker.pickFiles();
            if (r.isNotEmpty && r.first.path != null) {
              onFileSelected(r.first.path!);
            }
          },
        ),
      ],
    );
  }
}
