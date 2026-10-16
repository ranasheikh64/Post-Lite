import 'package:flutter/material.dart';
import 'form_data_file_cell.dart';
import 'table_field_autocomplete.dart';

class DynamicTableRow extends StatefulWidget {
  final String title;
  final Map<String, dynamic> item;
  final int index;
  final bool isLast;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onKeyChanged, onValChanged, onDescChanged;
  final VoidCallback onDelete;

  const DynamicTableRow({
    super.key,
    required this.title,
    required this.item,
    required this.index,
    required this.isLast,
    required this.onEnabledChanged,
    required this.onKeyChanged,
    required this.onValChanged,
    required this.onDescChanged,
    required this.onDelete,
  });

  @override
  State<DynamicTableRow> createState() => _DynamicTableRowState();
}

class _DynamicTableRowState extends State<DynamicTableRow> {
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
    final keyVal = widget.item['key']?.toString() ?? '';
    final valVal = widget.item['value']?.toString() ?? '';
    final descVal = widget.item['description']?.toString() ?? '';
    final isEnabled = widget.item['enabled'] ?? true;
    final hasContent = keyVal.isNotEmpty || valVal.isNotEmpty || descVal.isNotEmpty;
    final uid = widget.item['id'] ?? widget.index.toString();

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
            SizedBox(
              width: 36,
              child: Center(
                child: hasContent
                    ? Transform.scale(
                        scale: 0.85,
                        child: Checkbox(
                          value: isEnabled,
                          activeColor: const Color(0xFFFF6C37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          onChanged: (v) => widget.onEnabledChanged(v ?? true),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, indent: 9, endIndent: 9, color: Color(0xFF222638)),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: TableFieldAutocomplete(
                  key: ValueKey('${widget.title}_key_$uid'),
                  title: widget.title,
                  isKey: true,
                  initialValue: keyVal,
                  onChanged: widget.onKeyChanged,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: hasContent ? const Color(0xFF9CDCFE) : const Color(0xFFD4D4D4)),
                  decoration: _baseDec.copyWith(hintText: 'Key', hintStyle: const TextStyle(color: Color(0xFF4E536E), fontSize: 12.5, fontFamily: 'monospace')),
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, indent: 9, endIndent: 9, color: Color(0xFF222638)),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: (widget.title == 'Form Data' && widget.item['type'] == 'file')
                    ? FormDataFileCell(filePath: valVal, onFileSelected: widget.onValChanged)
                    : TableFieldAutocomplete(
                        key: ValueKey('${widget.title}_val_$uid'),
                        title: widget.title,
                        isKey: false,
                        headerKey: keyVal,
                        initialValue: valVal,
                        onChanged: widget.onValChanged,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: Color(0xFFCE9178)),
                        decoration: _baseDec.copyWith(hintText: 'Value', hintStyle: const TextStyle(color: Color(0xFF4E536E), fontSize: 12.5, fontFamily: 'monospace')),
                      ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, indent: 9, endIndent: 9, color: Color(0xFF222638)),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: TextFormField(
                  key: ValueKey('${widget.title}_desc_$uid'),
                  initialValue: descVal,
                  onChanged: widget.onDescChanged,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
                  decoration: _baseDec.copyWith(hintText: 'Description', hintStyle: const TextStyle(color: Color(0xFF4E536E), fontSize: 12.5)),
                ),
              ),
            ),
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
}
