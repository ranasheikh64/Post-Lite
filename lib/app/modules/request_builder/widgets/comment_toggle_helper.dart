import 'package:flutter/services.dart';

class CommentToggleHelper {
  static TextEditingValue? toggle(TextEditingValue value) {
    final text = value.text;
    final selection = value.selection;
    if (selection.baseOffset == -1 || selection.extentOffset == -1) return null;

    final start = selection.start;
    final end = selection.end;

    var lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    var lineEnd = end;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }

    final selectedLinesText = text.substring(lineStart, lineEnd);
    final lines = selectedLinesText.split('\n');
    final allCommented =
        lines.isNotEmpty &&
        lines.every((line) => line.trimLeft().startsWith('//'));

    final newLines = lines.map((line) {
      if (allCommented) {
        final idx = line.indexOf('//');
        if (idx != -1) {
          final after = line.substring(idx + 2);
          return line.substring(0, idx) +
              (after.startsWith(' ') ? after.substring(1) : after);
        }
        return line;
      } else {
        return '// $line';
      }
    }).toList();

    final newLinesText = newLines.join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, newLinesText);
    final diff = newLinesText.length - selectedLinesText.length;

    int newBase;
    int newExtent;

    if (selection.isCollapsed) {
      final newPos = (selection.baseOffset + diff).clamp(0, newText.length);
      newBase = newPos;
      newExtent = newPos;
    } else {
      final isForward = selection.baseOffset <= selection.extentOffset;
      final newStart = (start + (allCommented ? (diff < 0 ? -2 : 0) : 3))
          .clamp(0, newText.length);
      final newEnd = (end + diff).clamp(0, newText.length);
      newBase = isForward ? newStart : newEnd;
      newExtent = isForward ? newEnd : newStart;
    }

    newBase = newBase.clamp(0, newText.length);
    newExtent = newExtent.clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: newBase,
        extentOffset: newExtent,
      ),
    );
  }
}
