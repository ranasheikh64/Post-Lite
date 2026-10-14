import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postmanclone/app/widgets/variable_autocomplete.dart';

class EventRowItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isLast;
  final String requestId;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onDescChanged;
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
  Widget build(BuildContext context) {
    final keyText = item['key']?.toString() ?? '';
    final hasContent = keyText.trim().isNotEmpty;
    final isEnabled = item['enabled'] ?? true;
    final uniqueId = item['id'] ?? index.toString();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF232738), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Event Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: hasContent
                      ? (isEnabled ? const Color(0xFFFF6C37) : const Color(0xFF5E6482))
                      : Colors.transparent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: VariableAutocomplete(
                    key: ValueKey('${requestId}_event_key_$uniqueId'),
                    initialValue: keyText,
                    onChanged: onKeyChanged,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: hasContent ? FontWeight.w500 : FontWeight.normal,
                      color: hasContent ? const Color(0xFF9CDCFE) : const Color(0xFFE0E4F0),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add event',
                      hintStyle: TextStyle(color: Color(0xFF525875), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Listen Switch
          SizedBox(
            width: 70,
            child: Center(
              child: hasContent
                  ? Transform.scale(
                      scale: 0.68,
                      child: CupertinoSwitch(
                        value: isEnabled,
                        activeTrackColor: const Color(0xFFFF6C37),
                        onChanged: onEnabledChanged,
                      ),
                    )
                  : const SizedBox(height: 24),
            ),
          ),

          // Description
          Expanded(
            flex: 5,
            child: TextFormField(
              key: ValueKey('${requestId}_event_desc_$uniqueId'),
              initialValue: item['description']?.toString() ?? '',
              onChanged: onDescChanged,
              style: const TextStyle(fontSize: 13, color: Color(0xFFD4D4D4)),
              decoration: const InputDecoration(
                hintText: 'Add description',
                hintStyle: TextStyle(color: Color(0xFF525875), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),

          // Delete Action
          SizedBox(
            width: 32,
            child: (!isLast && hasContent)
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF757A95)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 14,
                    tooltip: 'Remove event',
                    hoverColor: Colors.red.withValues(alpha: 0.15),
                    onPressed: onDelete,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
