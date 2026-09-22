import 'package:flutter/material.dart';

class CustomJsonViewer extends StatefulWidget {
  final dynamic jsonObj;
  const CustomJsonViewer({Key? key, required this.jsonObj}) : super(key: key);

  @override
  _CustomJsonViewerState createState() => _CustomJsonViewerState();
}

class _CustomJsonViewerState extends State<CustomJsonViewer> {
  @override
  Widget build(BuildContext context) {
    return _JsonObjectViewer(
      jsonObj: widget.jsonObj, 
      isRoot: true, 
      isLast: true,
    );
  }
}

class _JsonObjectViewer extends StatefulWidget {
  final dynamic jsonObj;
  final bool isRoot;
  final bool isLast;
  final String? keyName;

  const _JsonObjectViewer({
    Key? key,
    required this.jsonObj,
    this.isRoot = false,
    this.isLast = true,
    this.keyName,
  }) : super(key: key);

  @override
  __JsonObjectViewerState createState() => __JsonObjectViewerState();
}

class __JsonObjectViewerState extends State<_JsonObjectViewer> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isMap = widget.jsonObj is Map;
    final isList = widget.jsonObj is List;

    if (!isMap && !isList) {
      return Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.keyName != null) 
              Text('"${widget.keyName}": ', style: const TextStyle(color: Color(0xFF66D9EF), fontSize: 13, fontFamily: 'monospace')),
            Flexible(child: _buildValue(widget.jsonObj)),
            if (!widget.isLast)
              const Text(',', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
          ],
        ),
      );
    }

    final openBracket = isMap ? '{' : '[';
    final closeBracket = isMap ? '}' : ']';
    
    // Build children
    List<Widget> children = [];
    if (isMap) {
      final map = widget.jsonObj as Map;
      final keys = map.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        children.add(_JsonObjectViewer(
          keyName: keys[i].toString(),
          jsonObj: map[keys[i]],
          isLast: i == keys.length - 1,
        ));
      }
    } else {
      final list = widget.jsonObj as List;
      for (int i = 0; i < list.length; i++) {
        children.add(_JsonObjectViewer(
          jsonObj: list[i],
          isLast: i == list.length - 1,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(() => isExpanded = !isExpanded),
              mouseCursor: SystemMouseCursors.click,
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.keyName != null)
              Text('"${widget.keyName}": ', style: const TextStyle(color: Color(0xFF66D9EF), fontSize: 13, fontFamily: 'monospace')),
            Text(openBracket, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
            if (!isExpanded) ...[
              const Text(' ... ', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'monospace')),
              Text('$closeBracket${widget.isLast ? '' : ','}', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
            ]
          ],
        ),
        if (isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text('$closeBracket${widget.isLast ? '' : ','}', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
          ),
        ]
      ],
    );
  }

  Widget _buildValue(dynamic value) {
    if (value is String) {
      return Text('"$value"', style: const TextStyle(color: Color(0xFFA6E22E), fontSize: 13, fontFamily: 'monospace'));
    } else if (value is num) {
      return Text('$value', style: const TextStyle(color: Color(0xFFFD971F), fontSize: 13, fontFamily: 'monospace'));
    } else if (value is bool) {
      return Text('$value', style: const TextStyle(color: Color(0xFFF92672), fontSize: 13, fontFamily: 'monospace'));
    } else if (value == null) {
      return const Text('null', style: TextStyle(color: Color(0xFFF92672), fontSize: 13, fontFamily: 'monospace'));
    }
    return Text('$value', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'));
  }
}
