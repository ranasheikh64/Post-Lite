import 'package:flutter/material.dart';

/// A custom TextEditingController that highlights comments (// and /* */)
/// and format-specific syntax colors (JSON, JavaScript, XML/HTML, Text).
class SyntaxHighlightingController extends TextEditingController {
  String _format;

  SyntaxHighlightingController({super.text, String format = 'json'})
      : _format = format.toLowerCase();

  String get format => _format;
  set format(String newFormat) {
    final normalized = newFormat.toLowerCase();
    if (_format != normalized) {
      _format = normalized;
      notifyListeners();
    }
  }

  @override
  set value(TextEditingValue newValue) {
    final textLength = newValue.text.length;
    final selection = newValue.selection;
    if (selection.baseOffset > textLength || selection.extentOffset > textLength) {
      final safeBase = selection.baseOffset.clamp(-1, textLength);
      final safeExtent = selection.extentOffset.clamp(-1, textLength);
      super.value = newValue.copyWith(
        selection: TextSelection(baseOffset: safeBase, extentOffset: safeExtent),
      );
      return;
    }
    super.value = newValue;
  }

  static const Color commentColor = Color(0xFF6A9955);
  static const Color keyColor = Color(0xFF9CDCFE);
  static const Color stringColor = Color(0xFFCE9178);
  static const Color numberColor = Color(0xFFB5CEA8);
  static const Color keywordColor = Color(0xFF569CD6);
  static const Color defaultColor = Color(0xFFD4D4D4);

  static final RegExp _jsonRegex = RegExp(
    r'(//[^\n]*|/\*[\s\S]*?\*/)|("(?:\\.|[^"\\])*")(\s*:)?|(\b(?:true|false|null)\b)|(-?\b\d+(?:\.\d+)?\b)',
    multiLine: true,
  );
  static final RegExp _jsRegex = RegExp(
    r'(//[^\n]*|/\*[\s\S]*?\*/)|("(?:\\.|[^"\\])*"|' r"'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)"
    r'|(\b(?:const|let|var|function|return|if|else|for|while|import|export|from|async|await|try|catch|class|new|true|false|null)\b)|(-?\b\d+(?:\.\d+)?\b)',
    multiLine: true,
  );
  static final RegExp _xmlRegex = RegExp(
    r'(<!--[\s\S]*?-->)|(</?[a-zA-Z0-9_\-:]+|/?>)|("(?:\\.|[^"\\])*"|' r"'(?:\\.|[^'\\])*')|([a-zA-Z0-9_\-]+(?=\s*=))",
    multiLine: true,
  );
  static final RegExp _textRegex = RegExp(r'(//[^\n]*|/\*[\s\S]*?\*/)', multiLine: true);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle(color: defaultColor, fontSize: 13, fontFamily: 'monospace');
    final currentText = text;
    if (currentText.isEmpty) return TextSpan(text: '', style: base);
    if (withComposing && value.isComposingRangeValid) {
      return super.buildTextSpan(context: context, style: base, withComposing: withComposing);
    }

    final spans = <TextSpan>[];
    int lastIndex = 0;
    final regex = _getRegex();

    for (final match in regex.allMatches(currentText)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: currentText.substring(lastIndex, match.start), style: base.copyWith(color: defaultColor)));
      }
      _buildSpan(match, spans, base);
      lastIndex = match.end;
    }

    if (lastIndex < currentText.length) {
      spans.add(TextSpan(text: currentText.substring(lastIndex), style: base.copyWith(color: defaultColor)));
    }
    return TextSpan(children: spans);
  }

  RegExp _getRegex() {
    switch (_format) {
      case 'javascript': return _jsRegex;
      case 'xml': case 'html': return _xmlRegex;
      case 'text': return _textRegex;
      default: return _jsonRegex;
    }
  }

  void _buildSpan(Match m, List<TextSpan> spans, TextStyle base) {
    if (_format == 'javascript') {
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: base.copyWith(color: commentColor, fontStyle: FontStyle.italic)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: base.copyWith(color: stringColor)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(text: m.group(3), style: base.copyWith(color: keywordColor)));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(text: m.group(4), style: base.copyWith(color: numberColor)));
      }
    } else if (_format == 'xml' || _format == 'html') {
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: base.copyWith(color: commentColor, fontStyle: FontStyle.italic)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: base.copyWith(color: keywordColor)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(text: m.group(3), style: base.copyWith(color: stringColor)));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(text: m.group(4), style: base.copyWith(color: keyColor)));
      }
    } else if (_format == 'text') {
      spans.add(TextSpan(text: m.group(0), style: base.copyWith(color: commentColor, fontStyle: FontStyle.italic)));
    } else {
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: base.copyWith(color: commentColor, fontStyle: FontStyle.italic)));
      } else if (m.group(2) != null) {
        final isKey = m.group(3) != null;
        spans.add(TextSpan(text: m.group(2), style: base.copyWith(color: isKey ? keyColor : stringColor)));
        if (isKey) spans.add(TextSpan(text: m.group(3), style: base.copyWith(color: defaultColor)));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(text: m.group(4), style: base.copyWith(color: keywordColor)));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(text: m.group(5), style: base.copyWith(color: numberColor)));
      }
    }
  }
}
