import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postmanclone/app/widgets/variable_autocomplete.dart';

class EventRowItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isLast;
  final String requestId;
  final ValueChanged<String> onKeyChanged, onDescChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  const EventRowItem({
    super.key,
    required this.item,
    required this.index,
    required this.isLast,
    required this.requestId,
    required this.onKeyChanged,
    required this.onEnabledChanged,
    required this.onDescChanged,
    required this.onDelete,
  });

  @override
  State<EventRowItem> createState() => _EventRowItemState();
}

class _EventRowItemState extends State<EventRowItem> {
  bool _isHovered = false;

  static const _baseDec = InputDecoration(
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 8),
  );

  @override
  Widget build(BuildContext context) {
    final keyText = widget.item['key']?.toString() ?? '';
    final hasContent = keyText.trim().isNotEmpty;
    final isEnabled = widget.item['enabled'] ?? true;
    final uniqueId = widget.item['id'] ?? widget.index.toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF1B1E2C) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFF222638))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(flex: 4, child: _buildKeyCol(keyText, hasContent, isEnabled, uniqueId)),
            Container(width: 1, height: 18, color: const Color(0xFF222638)),
            SizedBox(
              width: 76,
              child: Center(
                child: hasContent
                    ? Transform.scale(
                        scale: 0.65,
                        child: CupertinoSwitch(
                          value: isEnabled,
                          activeTrackColor: const Color(0xFFFF6C37),
                          onChanged: widget.onEnabledChanged,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Container(width: 1, height: 18, color: const Color(0xFF222638)),
            Expanded(flex: 5, child: _buildDescCol(uniqueId)),
            SizedBox(
              width: 32,
              child: (!widget.isLast && hasContent && _isHovered)
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF6B7280)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 12,
                      tooltip: 'Remove',
                      hoverColor: Colors.red.withValues(alpha: 0.15),
                      onPressed: widget.onDelete,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyCol(String keyText, bool hasContent, bool isEnabled, String uniqueId) {
    return Row(
      children: [
        Icon(
          hasContent ? Icons.bolt_rounded : Icons.add_rounded,
          size: 14,
          color: hasContent
              ? (isEnabled ? const Color(0xFFFF6C37) : const Color(0xFF5E6482))
              : const Color(0xFF4A4F68),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: VariableAutocomplete(
            key: ValueKey('${widget.requestId}_event_key_$uniqueId'),
            initialValue: keyText,
            onChanged: widget.onKeyChanged,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              fontWeight: hasContent ? FontWeight.w500 : FontWeight.normal,
              color: hasContent ? const Color(0xFF9CDCFE) : const Color(0xFFD4D4D4),
            ),
            decoration: _baseDec.copyWith(
              hintText: 'Add event name...',
              hintStyle: const TextStyle(color: Color(0xFF4E536E), fontSize: 12.5, fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescCol(String uniqueId) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: TextFormField(
        key: ValueKey('${widget.requestId}_event_desc_$uniqueId'),
        initialValue: widget.item['description']?.toString() ?? '',
        onChanged: widget.onDescChanged,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
        decoration: _baseDec.copyWith(
          hintText: 'Description',
          hintStyle: const TextStyle(color: Color(0xFF4E536E), fontSize: 12.5),
        ),
      ),
    );
  }
}
