import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';

class TableFieldTextEditingController extends TextEditingController {
  final bool isKey;

  TableFieldTextEditingController({super.text, this.isKey = false});

  String _clean(String s) => s.replaceAll('\n', ' ').replaceAll('\r', ' ');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) return TextSpan(style: style);

    Map<String, dynamic> variables = const {};
    try {
      if (Get.isRegistered<WorkspaceController>() && Get.isRegistered<RequestBuilderController>()) {
        final ws = Get.find<WorkspaceController>();
        final reqCtrl = Get.find<RequestBuilderController>();
        final reqId = reqCtrl.currentRequestId.value ?? '';
        variables = ws.getVariablesForRequest(reqId);
      }
    } catch (_) {}

    final spans = <TextSpan>[];
    int startIdx = 0;

    if (!isKey) {
      final authMatch = RegExp(r'^(Bearer|Basic|Digest|OAuth|Token)(\s+|$)', caseSensitive: false).firstMatch(text);
      if (authMatch != null) {
        spans.add(
          TextSpan(
            text: _clean(text.substring(0, authMatch.end)),
            style: (style ?? const TextStyle()).copyWith(
              color: const Color(0xFF569CD6),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        startIdx = authMatch.end;
      }
    }

    final remaining = text.substring(startIdx);
    final varRegex = RegExp(r'\{\{([^}]+)\}\}');
    int lastEnd = 0;

    for (final m in varRegex.allMatches(remaining)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: _clean(remaining.substring(lastEnd, m.start)), style: style));
      }
      final varName = m.group(1)!;
      final isResolved = variables.containsKey(varName);
      spans.add(
        TextSpan(
          text: _clean(m.group(0)!),
          style: (style ?? const TextStyle()).copyWith(
            color: isResolved ? const Color(0xFFFF9800) : Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastEnd = m.end;
    }

    if (lastEnd < remaining.length) {
      spans.add(TextSpan(text: _clean(remaining.substring(lastEnd)), style: style));
    }

    return TextSpan(style: style, children: spans);
  }
}
