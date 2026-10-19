import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'json_line_model.dart';
import 'json_url_span.dart';

class JsonContextMenu {
  static bool _isOpen = false;

  static Future<void> show(
    BuildContext context,
    Offset globalPosition,
    JsonLine line,
  ) async {
    if (_isOpen) return;

    final hasVal = line.isPrimitive && line.value != null;
    final hasKey = line.key.isNotEmpty;
    final hasUrl = line.matchedUrl != null;

    if (!hasVal && !hasKey && !hasUrl) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    _isOpen = true;
    String? selected;
    try {
      selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          globalPosition & const Size(40, 40),
          Offset.zero & overlay.size,
        ),
        color: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2C324A)),
        ),
        elevation: 8,
        items: [
          if (hasVal) ...[
            PopupMenuItem<String>(
              value: 'copy_value',
              height: 36,
              child: Row(
                children: [
                  const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFFF6C37)),
                  const SizedBox(width: 8),
                  const Text('Copy Value', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  const Spacer(),
                  Text(
                    _preview(line.rawValue),
                    style: const TextStyle(color: Color(0xFF8E92A8), fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            if (line.value!.startsWith('"') && line.value!.endsWith('"'))
              PopupMenuItem<String>(
                value: 'copy_quoted',
                height: 36,
                child: const Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 14, color: Color(0xFF8E92A8)),
                    SizedBox(width: 8),
                    Text('Copy with quotes', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  ],
                ),
              ),
          ],
          if (hasKey) ...[
            PopupMenuItem<String>(
              value: 'copy_key',
              height: 36,
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, size: 14, color: Color(0xFF8E92A8)),
                  const SizedBox(width: 8),
                  Text('Copy Key ("${line.key}")', style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'copy_pair',
              height: 36,
              child: const Row(
                children: [
                  Icon(Icons.data_object_rounded, size: 14, color: Color(0xFF8E92A8)),
                  SizedBox(width: 8),
                  Text('Copy Key: Value', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                ],
              ),
            ),
          ],
          if (hasUrl)
            PopupMenuItem<String>(
              value: 'open_url',
              height: 36,
              child: const Row(
                children: [
                  Icon(Icons.open_in_new, size: 14, color: Color(0xFF4DAAF8)),
                  SizedBox(width: 8),
                  Text('Open Link in Browser', style: TextStyle(color: Color(0xFF4DAAF8), fontSize: 12.5)),
                ],
              ),
            ),
        ],
      );
    } finally {
      _isOpen = false;
    }

    if (selected == null) return;

    if (selected == 'copy_value') {
      Clipboard.setData(ClipboardData(text: line.rawValue));
    } else if (selected == 'copy_quoted') {
      Clipboard.setData(ClipboardData(text: line.value ?? ''));
    } else if (selected == 'copy_key') {
      Clipboard.setData(ClipboardData(text: line.key));
    } else if (selected == 'copy_pair') {
      final pair = line.key.isNotEmpty ? '"${line.key}": ${line.value ?? ""}' : (line.value ?? '');
      Clipboard.setData(ClipboardData(text: pair));
    } else if (selected == 'open_url' && line.matchedUrl != null) {
      JsonUrlSpan.openUrlString(line.matchedUrl!);
    }
  }

  static String _preview(String str) {
    if (str.length <= 15) return str;
    return '${str.substring(0, 12)}...';
  }
}
