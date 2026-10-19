import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';

class ExpandedValueDialog extends StatefulWidget {
  final String keyName;
  final String initialValue;

  const ExpandedValueDialog({
    super.key,
    required this.keyName,
    required this.initialValue,
  });

  static Future<String?> show(BuildContext context, {required String keyName, required String initialValue}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => ExpandedValueDialog(keyName: keyName, initialValue: initialValue),
    );
  }

  @override
  State<ExpandedValueDialog> createState() => _ExpandedValueDialogState();
}

class _ExpandedValueDialogState extends State<ExpandedValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_controller.text);
      setState(() {
        _controller.text = const JsonEncoder.withIndent('  ').convert(decoded);
      });
    } catch (_) {
      CustomSnackbar.show(title: 'Invalid JSON', message: 'Could not parse text as JSON', isError: true);
    }
  }

  void _minifyJson() {
    try {
      final decoded = jsonDecode(_controller.text);
      setState(() {
        _controller.text = jsonEncode(decoded);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E2130),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF2C324A)),
      ),
      child: Container(
        width: 650,
        height: 480,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: Color(0xFFFF6C37), size: 20),
                const SizedBox(width: 8),
                Text('Edit Value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                if (widget.keyName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF2B3048), borderRadius: BorderRadius.circular(4)),
                    child: Text(widget.keyName, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF9CDCFE))),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: _formatJson,
                  icon: const Icon(Icons.auto_fix_high, size: 14, color: Color(0xFFFF6C37)),
                  label: const Text('Prettify JSON', style: TextStyle(fontSize: 11, color: Color(0xFFFF6C37))),
                ),
                TextButton.icon(
                  onPressed: _minifyJson,
                  icon: const Icon(Icons.compress, size: 14, color: Colors.white70),
                  label: const Text('Minify', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF12141F),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF282D42)),
                ),
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFCE9178), height: 1.4),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF333852))),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6C37)),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
