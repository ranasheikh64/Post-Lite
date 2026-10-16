import 'jsonc_tokenizer.dart';

class JsoncFormatter {
  static String format(String input, {String indent = '  '}) {
    final tokens = JsoncTokenizer.tokenize(input);
    if (tokens.isEmpty) return input;

    final sb = StringBuffer();
    int indentLevel = 0;
    bool isLineStart = true;
    bool justWroteStructuralNewline = false;
    int consecutiveNewlines = 0;

    void writeIndent() {
      if (isLineStart) {
        sb.write(indent * indentLevel);
        isLineStart = false;
        consecutiveNewlines = 0;
        justWroteStructuralNewline = false;
      }
    }

    void writeNewline({bool isStructural = false}) {
      sb.writeln();
      isLineStart = true;
      consecutiveNewlines++;
      justWroteStructuralNewline = isStructural;
    }

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == JsoncTokenType.newline) {
        if (justWroteStructuralNewline) {
          justWroteStructuralNewline = false;
          continue;
        }
        if (isLineStart && sb.isNotEmpty && consecutiveNewlines < 2) {
          writeNewline();
        } else if (!isLineStart) {
          writeNewline();
        }
        continue;
      }

      justWroteStructuralNewline = false;

      if (token.type == JsoncTokenType.openBrace || token.type == JsoncTokenType.openBracket) {
        int nextIdx = i + 1;
        while (nextIdx < tokens.length && tokens[nextIdx].type == JsoncTokenType.newline) {
          nextIdx++;
        }
        final isMatchingClose = (token.type == JsoncTokenType.openBrace &&
                nextIdx < tokens.length &&
                tokens[nextIdx].type == JsoncTokenType.closeBrace) ||
            (token.type == JsoncTokenType.openBracket &&
                nextIdx < tokens.length &&
                tokens[nextIdx].type == JsoncTokenType.closeBracket);

        if (isMatchingClose) {
          writeIndent();
          sb.write(token.text);
          sb.write(tokens[nextIdx].text);
          i = nextIdx;
          continue;
        }

        writeIndent();
        sb.write(token.text);
        indentLevel++;

        if (i + 1 < tokens.length &&
            (tokens[i + 1].type == JsoncTokenType.lineComment ||
                tokens[i + 1].type == JsoncTokenType.blockComment)) {
          sb.write(' ');
        } else {
          writeNewline(isStructural: true);
        }
        continue;
      }

      if (token.type == JsoncTokenType.closeBrace || token.type == JsoncTokenType.closeBracket) {
        if (!isLineStart) {
          writeNewline();
        }
        indentLevel = (indentLevel - 1).clamp(0, 100);
        writeIndent();
        sb.write(token.text);
        continue;
      }

      if (token.type == JsoncTokenType.comma) {
        sb.write(',');
        if (i + 1 < tokens.length &&
            (tokens[i + 1].type == JsoncTokenType.lineComment ||
                tokens[i + 1].type == JsoncTokenType.blockComment)) {
          sb.write(' ');
        } else {
          writeNewline(isStructural: true);
        }
        continue;
      }

      if (token.type == JsoncTokenType.colon) {
        sb.write(': ');
        continue;
      }

      if (token.type == JsoncTokenType.lineComment) {
        if (!isLineStart) {
          sb.write(' ');
        } else {
          writeIndent();
        }
        sb.write(token.text);
        isLineStart = false;
        continue;
      }

      if (token.type == JsoncTokenType.blockComment) {
        if (!isLineStart) {
          sb.write(' ');
        } else {
          writeIndent();
        }
        sb.write(token.text);
        continue;
      }

      writeIndent();
      sb.write(token.text);
    }

    return sb.toString().trimRight();
  }
}
