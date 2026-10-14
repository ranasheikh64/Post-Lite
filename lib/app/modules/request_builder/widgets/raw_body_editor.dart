import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';
import '../controllers/request_builder_controller.dart';
import 'syntax_highlighting_controller.dart';
import 'beautify_button.dart';
import 'code_formatter.dart';
import 'comment_toggle_helper.dart';

class RawBodyEditor extends StatefulWidget {
  final RequestBuilderController controller;
  final String bodyFormat;
  const RawBodyEditor({
    super.key,
    required this.controller,
    this.bodyFormat = 'json',
  });

  @override
  State<RawBodyEditor> createState() => _RawBodyEditorState();
}

class _RawBodyEditorState extends State<RawBodyEditor> {
  late SyntaxHighlightingController _textController;
  bool _isBeautified = false;
  Timer? _beautifyTimer;

  @override
  void initState() {
    super.initState();
    _textController = SyntaxHighlightingController(
      text: widget.controller.body.value is String
          ? widget.controller.body.value
          : '',
      format: widget.bodyFormat,
    );
  }

  @override
  void didUpdateWidget(RawBodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bodyFormat != oldWidget.bodyFormat) {
      _textController.format = widget.bodyFormat;
    }
    final currentVal = widget.controller.body.value is String
        ? widget.controller.body.value
        : '';
    if (currentVal != _textController.text) {
      _textController.text = currentVal;
    }
  }

  @override
  void dispose() {
    _beautifyTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _toggleComment() {
    final updated = CommentToggleHelper.toggle(_textController.value);
    if (updated != null) {
      setState(() => _textController.value = updated);
      widget.controller.body.value = updated.text;
    }
  }

  void _beautify() {
    final raw = _textController.text;
    if (raw.trim().isEmpty) return;

    try {
      final formatted = CodeFormatter.format(
        text: raw,
        format: widget.bodyFormat,
      );
      if (formatted != null && formatted != raw) {
        _beautifyTimer?.cancel();
        setState(() {
          _textController.text = formatted;
          _isBeautified = true;
        });
        widget.controller.body.value = formatted;
        widget.controller.hasUnsavedChanges.value = true;
        _beautifyTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isBeautified = false);
        });
      }
    } catch (_) {
      CustomSnackbar.show(
        title: 'Format Error',
        message: 'Could not format payload. Please check for syntax errors.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash, control: true): _toggleComment,
        const SingleActivator(LogicalKeyboardKey.slash, meta: true): _toggleComment,
        const SingleActivator(LogicalKeyboardKey.keyB, control: true, shift: true): _beautify,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true): _beautify,
      },
      child: Stack(
        children: [
          Focus(
            autofocus: true,
            child: TextFormField(
              key: ValueKey('${widget.controller.currentRequestId.value}_body_field'),
              controller: _textController,
              onChanged: (val) {
                if (_isBeautified) setState(() => _isBeautified = false);
                widget.controller.body.value = val;
              },
              maxLines: null,
              expands: true,
              style: const TextStyle(
                color: Color(0xFFD4D4D4),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: BeautifyButton(
              onPressed: _beautify,
              isBeautified: _isBeautified,
            ),
          ),
        ],
      ),
    );
  }
}
