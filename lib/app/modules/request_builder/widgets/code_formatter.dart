import 'jsonc_formatter.dart';

class CodeFormatter {
  static String? format({
    required String text,
    required String format,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final normFormat = format.toLowerCase();
    if (normFormat == 'json' || normFormat.isEmpty) {
      try {
        return JsoncFormatter.format(trimmed);
      } catch (_) {
        return null;
      }
    } else if (normFormat == 'xml' || normFormat == 'html') {
      return _formatXml(trimmed);
    }

    try {
      return JsoncFormatter.format(trimmed);
    } catch (_) {
      return null;
    }
  }

  static String stripJsonComments(String jsonString) {
    var inString = false;
    var inSingleComment = false;
    var inMultiComment = false;
    final result = StringBuffer();
    for (var i = 0; i < jsonString.length; i++) {
      if (inSingleComment) {
        if (jsonString[i] == '\n') {
          inSingleComment = false;
          result.write('\n');
        }
        continue;
      }
      if (inMultiComment) {
        if (jsonString[i] == '*' &&
            i + 1 < jsonString.length &&
            jsonString[i + 1] == '/') {
          inMultiComment = false;
          i++;
        }
        continue;
      }
      if (jsonString[i] == '"' && (i == 0 || jsonString[i - 1] != '\\')) {
        inString = !inString;
      }
      if (!inString && jsonString[i] == '/' && i + 1 < jsonString.length) {
        if (jsonString[i + 1] == '/') {
          inSingleComment = true;
          i++;
          continue;
        } else if (jsonString[i + 1] == '*') {
          inMultiComment = true;
          i++;
          continue;
        }
      }
      result.write(jsonString[i]);
    }
    return result.toString();
  }

  static String _formatXml(String xml) {
    var indent = 0;
    final sb = StringBuffer();
    final parts = xml.replaceAll('>', '>\n').replaceAll('<', '\n<').split('\n');
    for (var part in parts) {
      final p = part.trim();
      if (p.isEmpty) continue;
      if (p.startsWith('</')) indent = (indent - 1).clamp(0, 50);
      sb.writeln('${"  " * indent}$p');
      if (p.startsWith('<') &&
          !p.startsWith('</') &&
          !p.endsWith('/>') &&
          !p.startsWith('<?') &&
          !p.startsWith('<!--')) {
        indent++;
      }
    }
    return sb.toString().trim();
  }
}
