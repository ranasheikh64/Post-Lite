import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'manage_files_dialog.dart';

class FormDataFileCell extends StatelessWidget {
  final String filePath;
  final List<dynamic>? files;
  final void Function(List<Map<String, dynamic>> files, String displayValue) onFilesSelected;

  const FormDataFileCell({
    super.key,
    required this.filePath,
    this.files,
    required this.onFilesSelected,
  });

  List<Map<String, dynamic>> _getParsedFiles() {
    if (files != null && files!.isNotEmpty) {
      return List<Map<String, dynamic>>.from(files!.map((e) => Map<String, dynamic>.from(e as Map)));
    }
    if (filePath.isNotEmpty &&
        !filePath.contains(' files (') &&
        !RegExp(r'^\d+\s+files?\s*\(').hasMatch(filePath)) {
      final paths = filePath.split(RegExp(r'[,|]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
      return paths.map((p) => {'name': p.split(RegExp(r'[/\\]')).last, 'path': p, 'size': 0}).toList();
    }
    return [];
  }

  void _applyFiles(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      onFilesSelected([], '');
      return;
    }
    final displayText = list.length == 1
        ? list.first['name'] as String
        : '${list.length} files (${list.map((e) => e['name']).join(', ')})';
    onFilesSelected(list, displayText);
  }

  Future<void> _pickFiles() async {
    try {
      final picked = await FilePicker.pickFiles();
      if (picked.isNotEmpty) {
        final existing = _getParsedFiles();
        for (final f in picked) {
          Uint8List? bytes;
          try {
            bytes = await f.readAsBytes();
          } catch (_) {}
          existing.add({'name': f.name, 'size': bytes?.length ?? 0, 'bytes': bytes, 'path': f.path});
        }
        _applyFiles(existing);
      }
    } catch (_) {}
  }

  Future<void> _onRemoveTap(BuildContext context) async {
    final list = _getParsedFiles();
    if (list.length > 1) {
      final updated = await ManageFilesDialog.show(context, list);
      if (updated != null) _applyFiles(updated);
    } else {
      onFilesSelected([], '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _getParsedFiles();
    final hasFiles = list.isNotEmpty;
    final text = hasFiles
        ? (list.length == 1 ? list.first['name'] as String : '${list.length} files (${list.map((e) => e['name']).join(', ')})')
        : (filePath.isNotEmpty && !filePath.contains(' files (') ? filePath : 'Select file(s)');

    return Row(
      children: [
        Icon(
          hasFiles ? Icons.insert_drive_file_outlined : Icons.upload_file_outlined,
          size: 14,
          color: hasFiles ? const Color(0xFFFF6C37) : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: InkWell(
            onTap: () => hasFiles ? _onRemoveTap(context) : _pickFiles(),
            borderRadius: BorderRadius.circular(4),
            child: Tooltip(
              message: hasFiles
                  ? '$text (Click to manage/remove individual files)'
                  : (filePath.isNotEmpty
                      ? 'Files need to be selected. Click to browse'
                      : 'Click to pick file(s)'),
              child: Text(
                text,
                style: TextStyle(
                  color: hasFiles ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: hasFiles ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (hasFiles || filePath.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF8E92A8)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: list.length > 1 ? 'Manage/Remove files' : 'Remove file',
            splashRadius: 10,
            onPressed: () => hasFiles ? _onRemoveTap(context) : onFilesSelected([], ''),
          ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.file_upload_outlined, size: 15, color: Color(0xFFFF6C37)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Browse file(s)',
          splashRadius: 10,
          onPressed: _pickFiles,
        ),
      ],
    );
  }
}
