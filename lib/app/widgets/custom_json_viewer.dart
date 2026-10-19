import 'package:flutter/material.dart';
import 'json_viewer/json_line_model.dart';
import 'json_viewer/json_line_widget.dart';

export 'json_viewer/json_line_model.dart';

class CustomJsonViewer extends StatefulWidget {
  final dynamic jsonObj;

  const CustomJsonViewer({super.key, required this.jsonObj});

  @override
  State<CustomJsonViewer> createState() => _CustomJsonViewerState();
}

class _CustomJsonViewerState extends State<CustomJsonViewer> {
  List<JsonLine> lines = [];
  int currentLine = 1;

  @override
  void initState() {
    super.initState();
    _buildLines();
  }

  @override
  void didUpdateWidget(covariant CustomJsonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonObj.toString() != widget.jsonObj.toString()) {
      _buildLines();
    }
  }

  void _buildLines() {
    lines.clear();
    currentLine = 1;
    _traverse(widget.jsonObj, 0, null, true);
    setState(() {});
  }

  void _traverse(dynamic node, int indent, String? key, bool isLast) {
    if (node is Map) {
      final startLine = currentLine;
      lines.add(JsonLine(
        lineNumber: currentLine++,
        indentLevel: indent,
        key: key ?? '',
        isCollapsible: true,
        punctuation: '{',
        isLast: isLast,
      ));

      final entries = node.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        _traverse(entries[i].value, indent + 1, entries[i].key.toString(), i == entries.length - 1);
      }

      lines[startLine - 1].endLineNumber = currentLine;
      lines.add(JsonLine(
        lineNumber: currentLine++,
        indentLevel: indent,
        isEndNode: true,
        punctuation: '}${isLast ? "" : ","}',
        isLast: isLast,
      ));
    } else if (node is List) {
      final startLine = currentLine;
      lines.add(JsonLine(
        lineNumber: currentLine++,
        indentLevel: indent,
        key: key ?? '',
        isCollapsible: true,
        punctuation: '[',
        isLast: isLast,
      ));

      for (var i = 0; i < node.length; i++) {
        _traverse(node[i], indent + 1, null, i == node.length - 1);
      }

      lines[startLine - 1].endLineNumber = currentLine;
      lines.add(JsonLine(
        lineNumber: currentLine++,
        indentLevel: indent,
        isEndNode: true,
        punctuation: ']${isLast ? "" : ","}',
        isLast: isLast,
      ));
    } else {
      String valStr = node is String ? '"$node"' : (node?.toString() ?? 'null');
      lines.add(JsonLine(
        lineNumber: currentLine++,
        indentLevel: indent,
        key: key ?? '',
        value: valStr,
        isPrimitive: true,
        punctuation: isLast ? '' : ',',
        isLast: isLast,
      ));
    }
  }

  void _toggleCollapse(int index) {
    setState(() {
      lines[index].isCollapsed = !lines[index].isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<JsonLine> visibleLines = [];
    int skipUntil = -1;

    for (int i = 0; i < lines.length; i++) {
      if (i < skipUntil) continue;
      final line = lines[i];
      visibleLines.add(line);
      if (line.isCollapsible && line.isCollapsed && line.endLineNumber != null) {
        skipUntil = line.endLineNumber!;
      }
    }

    return SelectionArea(
      child: ListView.builder(
        itemCount: visibleLines.length,
        itemBuilder: (context, index) {
          final line = visibleLines[index];
          return JsonLineWidget(
            line: line,
            originalIndex: lines.indexOf(line),
            onToggleCollapse: () => _toggleCollapse(lines.indexOf(line)),
          );
        },
      ),
    );
  }
}
