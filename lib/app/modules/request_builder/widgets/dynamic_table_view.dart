import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dynamic_column_header.dart';
import 'dynamic_table_header.dart';
import 'dynamic_table_row.dart';

class DynamicTableView extends StatelessWidget {
  final String title;
  final RxList<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  const DynamicTableView({
    super.key,
    required this.title,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final count = items
              .where((e) =>
                  e['enabled'] == true &&
                  ((e['key']?.toString().trim().isNotEmpty ?? false) ||
                      (e['value']?.toString().trim().isNotEmpty ?? false)))
              .length;
          return DynamicTableHeader(title: title, activeCount: count);
        }),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131520),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF24283B)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const DynamicColumnHeader(),
                  const Divider(height: 1, thickness: 1, color: Color(0xFF24283B)),
                  Expanded(
                    child: Obx(() {
                      _ensureEmptyRow();

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return DynamicTableRow(
                            key: ValueKey('${title}_row_${item['id'] ?? idx}'),
                            title: title,
                            item: item,
                            index: idx,
                            isLast: idx == items.length - 1,
                            onEnabledChanged: (val) => _updateItem(idx, 'enabled', val),
                            onKeyChanged: (val) => _updateItem(idx, 'key', val),
                            onValChanged: (val) => _updateItem(idx, 'value', val),
                            onDescChanged: (val) => _updateItem(idx, 'description', val),
                            onTypeChanged: (val) => _updateItem(idx, 'type', val),
                            onFilesChanged: (files, displayVal) {
                              final list = List<Map<String, dynamic>>.from(items);
                              list[idx]['files'] = files;
                              list[idx]['value'] = displayVal;
                              items.value = list;
                              onChanged();
                            },
                            onDelete: () {
                              final list = List<Map<String, dynamic>>.from(items);
                              list.removeAt(idx);
                              items.value = list;
                              onChanged();
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _ensureEmptyRow() {
    final needsEmpty = items.isEmpty ||
        (items.last['key']?.toString().isNotEmpty == true ||
            items.last['value']?.toString().isNotEmpty == true ||
            items.last['description']?.toString().isNotEmpty == true);

    if (needsEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        items.add({
          'key': '',
          'value': '',
          'type': 'text',
          'description': '',
          'enabled': true,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      });
    }
  }

  void _updateItem(int idx, String field, dynamic val) {
    final list = List<Map<String, dynamic>>.from(items);
    list[idx][field] = val;
    items.value = list;
    onChanged();
  }
}
