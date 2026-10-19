import 'package:flutter/material.dart';
import 'expanded_value_dialog.dart';
import 'form_data_file_cell.dart';
import 'table_field_autocomplete.dart';

class DynamicTableValCell extends StatelessWidget {
  final String title;
  final String uid;
  final String keyVal;
  final String valVal;
  final String currentType;
  final List<dynamic>? files;
  final ValueChanged<String> onValChanged;
  final void Function(List<Map<String, dynamic>> files, String displayValue)? onFilesChanged;

  const DynamicTableValCell({
    super.key,
    required this.title,
    required this.uid,
    required this.keyVal,
    required this.valVal,
    required this.currentType,
    this.files,
    required this.onValChanged,
    this.onFilesChanged,
  });

  Future<void> _openExpandedEditor(BuildContext context) async {
    final result = await ExpandedValueDialog.show(
      context,
      keyName: keyVal,
      initialValue: valVal,
    );
    if (result != null) {
      onValChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (title == 'Form Data' && currentType == 'file') {
      return FormDataFileCell(
        filePath: valVal,
        files: files,
        onFilesSelected: (selectedFiles, displayVal) {
          onFilesChanged?.call(selectedFiles, displayVal);
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: TableFieldAutocomplete(
            key: ValueKey('${title}_val_$uid'),
            title: title,
            isKey: false,
            headerKey: keyVal,
            initialValue: valVal,
            onChanged: onValChanged,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: Color(0xFFCE9178),
            ),
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              hintText: 'Value',
              hintStyle: TextStyle(
                color: Color(0xFF4E536E),
                fontSize: 12.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_full_rounded, size: 12, color: Color(0xFF8E92A8)),
          tooltip: 'Expand text editor (JSON/Multiline)',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 10,
          hoverColor: const Color(0xFFFF6C37).withValues(alpha: 0.15),
          onPressed: () => _openExpandedEditor(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
