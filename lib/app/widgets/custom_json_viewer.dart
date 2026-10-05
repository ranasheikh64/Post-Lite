import 'package:flutter/material.dart';

class JsonLine {
  final int lineNumber;
  final int indentLevel;
  final String key;
  final String? value;
  final bool isPrimitive;
  final bool isCollapsible;
  final bool isEndNode;
  final String? punctuation;
  final bool isLast;
  int? endLineNumber;
  bool isCollapsed = false;

  JsonLine({
    required this.lineNumber,
    required this.indentLevel,
    this.key = '',
    this.value,
    this.isPrimitive = false,
    this.isCollapsible = false,
    this.isEndNode = false,
    this.punctuation,
    this.isLast = true,
  });
}

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
      String valStr;
      if (node is String) {
        valStr = '"$node"';
      } else {
        valStr = node?.toString() ?? 'null';
      }
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
        skipUntil = line.endLineNumber!; // endLineNumber is the 1-based line number of the end node. So its index is endLineNumber - 1.
        // If endLineNumber is 5, index is 4. skipUntil = 5 means we skip indices < 5. So index 4 is skipped! Perfect.
      }
    }

    return SelectionArea(
      child: ListView.builder(
        itemCount: visibleLines.length,
        itemBuilder: (context, index) {
          final line = visibleLines[index];
          return _buildLineWidget(line, lines.indexOf(line));
        },
      ),
    );
  }

  Widget _buildLineWidget(JsonLine line, int originalIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line number
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
        
        // Fold arrow
        SizedBox(
          width: 20,
          child: line.isCollapsible
              ? InkWell(
                  onTap: () => _toggleCollapse(originalIndex),
                  child: Icon(
                    line.isCollapsed ? Icons.arrow_right : Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        
        // Indentation
        SizedBox(width: line.indentLevel * 16.0),
        
        // Content
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (line.key.isNotEmpty)
                  TextSpan(
                    text: '"${line.key}": ',
                    style: const TextStyle(color: Color(0xFF9CDCFE), fontSize: 13, fontFamily: 'monospace', height: 1.6), // Light blue
                  ),
                if (line.isCollapsible)
                  TextSpan(
                    text: line.punctuation! + (line.isCollapsed ? ' ... ${line.punctuation == "{" ? "}" : "]"}${line.isLast ? "" : ","}' : ''),
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6),
                  ),
                if (line.isEndNode)
                  TextSpan(
                    text: line.punctuation!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6),
                  ),
                if (line.isPrimitive)
                  TextSpan(
                    text: line.value!,
                    style: TextStyle(
                      color: _getValueColor(line.value),
                      fontSize: 13, 
                      fontFamily: 'monospace',
                      height: 1.6
                    ),
                  ),
                if (line.isPrimitive && line.punctuation!.isNotEmpty)
                  TextSpan(
                    text: line.punctuation!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace', height: 1.6),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getValueColor(String? value) {
    if (value == null || value == 'null') return const Color(0xFF569CD6); // Blue
    if (value.startsWith('"')) return const Color(0xFFCE9178); // Orange string
    if (value == 'true' || value == 'false') return const Color(0xFF569CD6);
    return const Color(0xFFB5CEA8); // Light green numbers
  }
}
