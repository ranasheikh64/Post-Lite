import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'json_line_model.dart';
import 'json_url_span.dart';

class JsonContextMenuCard extends StatelessWidget {
  final JsonLine line;
  final bool hasVal;
  final bool hasKey;
  final bool hasUrl;
  final VoidCallback onClose;

  const JsonContextMenuCard({
    super.key,
    required this.line,
    required this.hasVal,
    required this.hasKey,
    required this.hasUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2130),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2C324A)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasVal) ...[
                _buildItem(
                  icon: Icons.copy_rounded,
                  iconColor: const Color(0xFFFF6C37),
                  title: 'Copy Value',
                  trailing: _preview(line.rawValue),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: line.rawValue));
                    onClose();
                  },
                ),
                if (line.value!.startsWith('"') && line.value!.endsWith('"'))
                  _buildItem(
                    icon: Icons.format_quote_rounded,
                    title: 'Copy with quotes',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: line.value ?? ''));
                      onClose();
                    },
                  ),
              ],
              if (hasKey) ...[
                _buildItem(
                  icon: Icons.key_rounded,
                  title: 'Copy Key ("${line.key}")',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: line.key));
                    onClose();
                  },
                ),
                _buildItem(
                  icon: Icons.data_object_rounded,
                  title: 'Copy Key: Value',
                  onTap: () {
                    final pair = line.key.isNotEmpty ? '"${line.key}": ${line.value ?? ""}' : (line.value ?? '');
                    Clipboard.setData(ClipboardData(text: pair));
                    onClose();
                  },
                ),
              ],
              if (hasUrl)
                _buildItem(
                  icon: Icons.open_in_new,
                  iconColor: const Color(0xFF4DAAF8),
                  title: 'Open Link in Browser',
                  textColor: const Color(0xFF4DAAF8),
                  onTap: () {
                    if (line.matchedUrl != null) JsonUrlSpan.openUrlString(line.matchedUrl!);
                    onClose();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF8E92A8),
    Color textColor = Colors.white,
    String? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFF282C3F),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: TextStyle(color: textColor, fontSize: 12.5), overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(trailing, style: const TextStyle(color: Color(0xFF8E92A8), fontSize: 11, fontFamily: 'monospace')),
            ],
          ],
        ),
      ),
    );
  }

  String _preview(String str) => str.length <= 14 ? str : '${str.substring(0, 11)}...';
}
