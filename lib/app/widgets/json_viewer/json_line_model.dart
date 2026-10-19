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

  static final RegExp _urlRegex = RegExp(r'https?://[^\s"\\]+');

  String? get matchedUrl => isPrimitive && value != null ? _urlRegex.firstMatch(value!)?.group(0) : null;
  Match? get urlMatch => isPrimitive && value != null ? _urlRegex.firstMatch(value!) : null;

  String get rawValue {
    if (value == null) return '';
    if (value!.startsWith('"') && value!.endsWith('"') && value!.length >= 2) {
      return value!.substring(1, value!.length - 1);
    }
    return value!;
  }

  Color get valueColor {
    if (value == null || value == 'null') return const Color(0xFF569CD6);
    if (value!.startsWith('"')) return const Color(0xFFCE9178);
    if (value == 'true' || value == 'false') return const Color(0xFF569CD6);
    return const Color(0xFFB5CEA8);
  }
}
