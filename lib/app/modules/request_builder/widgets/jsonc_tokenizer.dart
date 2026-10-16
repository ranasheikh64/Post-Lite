enum JsoncTokenType {
  openBrace,
  closeBrace,
  openBracket,
  closeBracket,
  colon,
  comma,
  string,
  lineComment,
  blockComment,
  newline,
  other,
}

class JsoncToken {
  final JsoncTokenType type;
  final String text;
  JsoncToken(this.type, this.text);
}

class JsoncTokenizer {
  static List<JsoncToken> tokenize(String input) {
    final tokens = <JsoncToken>[];
    int i = 0;
    final len = input.length;

    while (i < len) {
      final char = input[i];

      if (char == ' ' || char == '\t' || char == '\r') {
        i++;
        continue;
      }

      if (char == '\n') {
        tokens.add(JsoncToken(JsoncTokenType.newline, '\n'));
        i++;
        continue;
      }

      if (char == '/' && i + 1 < len) {
        if (input[i + 1] == '/') {
          int start = i;
          while (i < len && input[i] != '\n') {
            i++;
          }
          tokens.add(JsoncToken(JsoncTokenType.lineComment, input.substring(start, i).trimRight()));
          continue;
        } else if (input[i + 1] == '*') {
          int start = i;
          i += 2;
          while (i < len && !(input[i - 1] == '*' && input[i] == '/')) {
            i++;
          }
          if (i < len) i++;
          tokens.add(JsoncToken(JsoncTokenType.blockComment, input.substring(start, i).trim()));
          continue;
        }
      }

      if (char == '"' || char == "'") {
        final quote = char;
        int start = i;
        i++;
        while (i < len) {
          if (input[i] == '\\' && i + 1 < len) {
            i += 2;
          } else if (input[i] == quote) {
            i++;
            break;
          } else {
            i++;
          }
        }
        tokens.add(JsoncToken(JsoncTokenType.string, input.substring(start, i)));
        continue;
      }

      if (char == '{') {
        tokens.add(JsoncToken(JsoncTokenType.openBrace, '{'));
        i++;
        continue;
      }
      if (char == '}') {
        tokens.add(JsoncToken(JsoncTokenType.closeBrace, '}'));
        i++;
        continue;
      }
      if (char == '[') {
        tokens.add(JsoncToken(JsoncTokenType.openBracket, '['));
        i++;
        continue;
      }
      if (char == ']') {
        tokens.add(JsoncToken(JsoncTokenType.closeBracket, ']'));
        i++;
        continue;
      }
      if (char == ':') {
        tokens.add(JsoncToken(JsoncTokenType.colon, ':'));
        i++;
        continue;
      }
      if (char == ',') {
        tokens.add(JsoncToken(JsoncTokenType.comma, ','));
        i++;
        continue;
      }

      int start = i;
      while (i < len &&
          input[i] != ' ' &&
          input[i] != '\t' &&
          input[i] != '\r' &&
          input[i] != '\n' &&
          input[i] != '{' &&
          input[i] != '}' &&
          input[i] != '[' &&
          input[i] != ']' &&
          input[i] != ':' &&
          input[i] != ',' &&
          input[i] != '"' &&
          input[i] != "'" &&
          !(input[i] == '/' && i + 1 < len && (input[i + 1] == '/' || input[i + 1] == '*'))) {
        i++;
      }
      tokens.add(JsoncToken(JsoncTokenType.other, input.substring(start, i)));
    }

    return tokens;
  }
}
