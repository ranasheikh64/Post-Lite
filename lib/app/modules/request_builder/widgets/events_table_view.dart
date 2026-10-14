import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'event_row_item.dart';
import 'events_column_header.dart';
import 'events_table_header.dart';

class EventsTableView extends StatelessWidget {
  final RxList<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  const EventsTableView({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final count = items
              .where((e) =>
                  e['enabled'] == true &&
                  (e['key']?.toString().trim().isNotEmpty ?? false))
              .length;
          return EventsTableHeader(listeningCount: count);
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
                  const EventsColumnHeader(),
                  const Divider(height: 1, thickness: 1, color: Color(0xFF24283B)),
                  Expanded(
                    child: Obx(() {
                      _ensureEmptyRow();
                      final reqId = controller.currentRequestId.value ?? 'req';

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return EventRowItem(
                            key: ValueKey('${reqId}_event_row_${item['id'] ?? idx}'),
                            item: item,
                            index: idx,
                            isLast: idx == items.length - 1,
                            requestId: reqId,
                            onKeyChanged: (val) => _updateItem(idx, 'key', val),
                            onEnabledChanged: (val) => _updateItem(idx, 'enabled', val),
                            onDescChanged: (val) => _updateItem(idx, 'description', val),
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
            items.last['description']?.toString().isNotEmpty == true);
    if (needsEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        items.add({
          'key': '',
          'value': '',
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
