import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'json_context_menu_card.dart';
import 'json_line_model.dart';

class JsonContextMenu {
  static OverlayEntry? _entry;

  static bool get isOpen => _entry != null;

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static void show(
    BuildContext context,
    Offset globalPosition,
    JsonLine line,
  ) {
    if (HardwareKeyboard.instance.isShiftPressed || HardwareKeyboard.instance.isAltPressed) {
      return;
    }
    hide();

    final hasVal = line.isPrimitive && line.value != null;
    final hasKey = line.key.isNotEmpty;
    final hasUrl = line.matchedUrl != null;

    if (!hasVal && !hasKey && !hasUrl) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox = overlay.context.findRenderObject() as RenderBox?;
    final screenSize = renderBox?.size ?? MediaQuery.of(context).size;

    const double menuWidth = 250.0;
    int itemCount = (hasVal ? 1 : 0) +
        (hasVal && line.value!.startsWith('"') && line.value!.endsWith('"') ? 1 : 0) +
        (hasKey ? 2 : 0) +
        (hasUrl ? 1 : 0);
    double menuHeight = itemCount * 32.0 + 20.0;

    double left = globalPosition.dx;
    double top = globalPosition.dy;

    if (left + menuWidth > screenSize.width - 12) {
      left = screenSize.width - menuWidth - 12;
    }
    if (top + menuHeight > screenSize.height - 12) {
      top = screenSize.height - menuHeight - 12;
    }
    if (left < 12) left = 12;
    if (top < 12) top = 12;

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => hide(),
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) hide();
              },
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: JsonContextMenuCard(
              line: line,
              hasVal: hasVal,
              hasKey: hasKey,
              hasUrl: hasUrl,
              onClose: hide,
            ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);
  }
}
