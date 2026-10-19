import 'package:flutter/material.dart';
import 'form_data_type_selector.dart';
import 'table_field_autocomplete.dart';

class DynamicTableKeyCell extends StatelessWidget {
  final String title;
  final String uid;
  final String keyVal;
  final bool hasContent;
  final String currentType;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<String>? onTypeChanged;

  const DynamicTableKeyCell({
    super.key,
    required this.title,
    required this.uid,
    required this.keyVal,
    required this.hasContent,
    required this.currentType,
    required this.onKeyChanged,
    this.onTypeChanged,
  });

  void _onKeyInput(String val) {
    if (title == 'Form Data') {
      final lower = val.trim().toLowerCase();
      const fileKeys = {
        'file', 'files', 'image', 'images', 'photo', 'photos',
        'picture', 'avatar', 'attachment', 'doc', 'document', 'pdf'
      };
      if (fileKeys.contains(lower) && currentType != 'file') {
        onTypeChanged?.call('file');
      }
    }
    onKeyChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    const baseDec = InputDecoration(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 8),
    );

    return Row(
      children: [
        Expanded(
          child: TableFieldAutocomplete(
            key: ValueKey('${title}_key_$uid'),
            title: title,
            isKey: true,
            initialValue: keyVal,
            onChanged: _onKeyInput,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: hasContent ? const Color(0xFF9CDCFE) : const Color(0xFFD4D4D4),
            ),
            decoration: baseDec.copyWith(
              hintText: 'Key',
              hintStyle: const TextStyle(color: Color(0xFF4E536E), fontSize: 12.5, fontFamily: 'monospace'),
            ),
          ),
        ),
        if (title == 'Form Data' && hasContent) ...[
          const SizedBox(width: 4),
          FormDataTypeSelector(
            currentType: currentType,
            onTypeChanged: (t) => onTypeChanged?.call(t),
          ),
        ],
      ],
    );
  }
}
