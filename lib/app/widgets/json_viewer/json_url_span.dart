import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class JsonUrlSpan extends StatefulWidget {
  final String fullValue, url, before, after;
  final Color baseColor;

  const JsonUrlSpan({
    super.key,
    required this.fullValue,
    required this.url,
    required this.before,
    required this.after,
    required this.baseColor,
  });

  static Future<void> openUrlString(String rawUrl) async {
    final cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) return;

    if (!kIsWeb) {
      try {
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          final res = await io.Process.run('open', [cleanUrl]);
          if (res.exitCode == 0) return;
        } else if (defaultTargetPlatform == TargetPlatform.windows) {
          await io.Process.run('cmd', ['/c', 'start', '', cleanUrl]);
          return;
        } else if (defaultTargetPlatform == TargetPlatform.linux) {
          await io.Process.run('xdg-open', [cleanUrl]);
          return;
        }
      } catch (_) {}
    }

    try {
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    Clipboard.setData(ClipboardData(text: cleanUrl));
  }

  @override
  State<JsonUrlSpan> createState() => _JsonUrlSpanState();
}

class _JsonUrlSpanState extends State<JsonUrlSpan> {
  bool _isHovered = false;
  static DateTime _lastOpened = DateTime(0);

  Future<void> _openLink() async {
    final now = DateTime.now();
    if (now.difference(_lastOpened).inMilliseconds < 1000) return;
    _lastOpened = now;
    await JsonUrlSpan.openUrlString(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final hint = isMac ? 'Click or Cmd + Click to open link' : 'Click or Ctrl + Click to open link';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openLink,
        child: Tooltip(
          message: '$hint\n${widget.url}',
          waitDuration: const Duration(milliseconds: 200),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.before.isNotEmpty)
                Text(
                  widget.before,
                  style: TextStyle(color: widget.baseColor, fontSize: 13, fontFamily: 'monospace', height: 1.6),
                ),
              Text(
                widget.url,
                style: TextStyle(
                  color: _isHovered ? const Color(0xFF4DAAF8) : const Color(0xFF61AFEF),
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.6,
                  decoration: TextDecoration.underline,
                  decorationColor: _isHovered ? const Color(0xFF4DAAF8) : const Color(0xFF61AFEF),
                ),
              ),
              if (widget.after.isNotEmpty)
                Text(
                  widget.after,
                  style: TextStyle(color: widget.baseColor, fontSize: 13, fontFamily: 'monospace', height: 1.6),
                ),
              const SizedBox(width: 4),
              InkWell(
                onTap: _openLink,
                borderRadius: BorderRadius.circular(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: _isHovered ? const Color(0xFF4DAAF8) : const Color(0xFF61AFEF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
