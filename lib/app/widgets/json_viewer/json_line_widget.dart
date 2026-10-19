import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'json_line_model.dart';
import 'json_url_span.dart';
import 'json_context_menu.dart';

class JsonLineWidget extends StatefulWidget {
  final JsonLine line;
  final int originalIndex;
  final VoidCallback onToggleCollapse;

  const JsonLineWidget({
    super.key,
    required this.line,
    required this.originalIndex,
    required this.onToggleCollapse,
  });

  @override
  State<JsonLineWidget> createState() => _JsonLineWidgetState();
}

class _JsonLineWidgetState extends State<JsonLineWidget> {
  bool _isHovered = false;

  void _copyValue() {
    Clipboard.setData(ClipboardData(text: widget.line.rawValue));
  }

  Widget _buildContent() {
    final line = widget.line;
    final urlMatch = line.urlMatch;
    if (line.isPrimitive && urlMatch != null && line.value != null) {
      final val = line.value!;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (line.key.isNotEmpty)
            Text('"${line.key}": ', style: const TextStyle(color: Color(0xFF9CDCFE), fontSize: 13, fontFamily: 'monospace', height: 1.6)),
          JsonUrlSpan(
            fullValue: val,
            url: val.substring(urlMatch.start, urlMatch.end),
            before: val.substring(0, urlMatch.start),
            after: val.substring(urlMatch.end),
            baseColor: line.valueColor,
          ),
          if (line.punctuation?.isNotEmpty == true)
            Text(line.punctuation!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6)),
        ],
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          if (line.key.isNotEmpty)
            TextSpan(text: '"${line.key}": ', style: const TextStyle(color: Color(0xFF9CDCFE), fontSize: 13, fontFamily: 'monospace', height: 1.6)),
          if (line.isCollapsible)
            TextSpan(
              text: line.punctuation! + (line.isCollapsed ? ' ... ${line.punctuation == "{" ? "}" : "]"}${line.isLast ? "" : ","}' : ''),
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6),
            ),
          if (line.isEndNode)
            TextSpan(text: line.punctuation!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6)),
          if (line.isPrimitive)
            TextSpan(text: line.value!, style: TextStyle(color: line.valueColor, fontSize: 13, fontFamily: 'monospace', height: 1.6)),
          if (line.isPrimitive && line.punctuation?.isNotEmpty == true)
            TextSpan(text: line.punctuation!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (d) => JsonContextMenu.show(context, d.globalPosition, line),
        child: Container(
          color: _isHovered ? const Color(0xFF1E2130) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 0.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    line.lineNumber.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white30, fontSize: 13, fontFamily: 'monospace', height: 1.6),
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                child: line.isCollapsible
                    ? InkWell(
                        onTap: widget.onToggleCollapse,
                        child: Icon(line.isCollapsed ? Icons.arrow_right : Icons.arrow_drop_down, size: 18, color: Colors.grey),
                      )
                    : null,
              ),
              SizedBox(width: line.indentLevel * 16.0),
              Expanded(child: _buildContent()),
              if (_isHovered && line.isPrimitive && line.value != null)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF8E92A8)),
                  tooltip: 'Right click or click to copy value',
                  splashRadius: 12,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  onPressed: _copyValue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
