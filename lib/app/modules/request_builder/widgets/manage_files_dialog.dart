import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ManageFilesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> files;
  const ManageFilesDialog({super.key, required this.files});

  static Future<List<Map<String, dynamic>>?> show(BuildContext context, List<Map<String, dynamic>> files) {
    return showDialog<List<Map<String, dynamic>>>(context: context, builder: (ctx) => ManageFilesDialog(files: files));
  }

  @override
  State<ManageFilesDialog> createState() => _ManageFilesDialogState();
}

class _ManageFilesDialogState extends State<ManageFilesDialog> {
  late List<Map<String, dynamic>> _files;

  @override
  void initState() {
    super.initState();
    _files = List<Map<String, dynamic>>.from(widget.files);
  }

  Future<void> _addMoreFiles() async {
    try {
      final picked = await FilePicker.pickFiles();
      if (picked.isNotEmpty) {
        for (final f in picked) {
          Uint8List? bytes;
          try {
            bytes = await f.readAsBytes();
          } catch (_) {}
          _files.add({'name': f.name, 'size': bytes?.length ?? 0, 'bytes': bytes, 'path': f.path});
        }
        setState(() {});
      }
    } catch (_) {}
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E2130),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF2C324A))),
      child: Container(
        width: 480,
        height: 380,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open_rounded, color: Color(0xFFFF6C37), size: 18),
                const SizedBox(width: 8),
                Text('Selected Files (${_files.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white70), onPressed: () => Navigator.of(context).pop(_files)),
              ],
            ),
            const Divider(color: Color(0xFF282D42), height: 16),
            Expanded(
              child: _files.isEmpty
                  ? const Center(child: Text('No files selected', style: TextStyle(color: Color(0xFF8E92A8), fontSize: 13)))
                  : ListView.separated(
                      itemCount: _files.length,
                      separatorBuilder: (ctx, i) => const Divider(color: Color(0xFF23273A), height: 1),
                      itemBuilder: (ctx, i) {
                        final file = _files[i];
                        final name = file['name']?.toString() ?? 'Unnamed';
                        final size = file['size'] is int ? file['size'] as int : 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file_outlined, size: 16, color: Color(0xFFFF6C37)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                                    if (size > 0) Text(_formatSize(size), style: const TextStyle(color: Color(0xFF8E92A8), fontSize: 10.5)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                tooltip: 'Remove this file',
                                splashRadius: 14,
                                onPressed: () => setState(() => _files.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(color: Color(0xFF282D42), height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _addMoreFiles,
                  icon: const Icon(Icons.add, size: 14, color: Color(0xFFFF6C37)),
                  label: const Text('Add More', style: TextStyle(color: Color(0xFFFF6C37), fontSize: 12)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF6C37))),
                ),
                const SizedBox(width: 8),
                if (_files.isNotEmpty)
                  TextButton(onPressed: () => setState(() => _files.clear()), child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_files),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6C37)),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
