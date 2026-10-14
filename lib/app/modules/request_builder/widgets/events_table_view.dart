import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'event_row_item.dart';
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
          final listeningCount = items
              .where((e) =>
                  e['enabled'] == true &&
                  (e['key']?.toString().trim().isNotEmpty ?? false))
              .length;
          return EventsTableHeader(listeningCount: listeningCount);
        }),
        Expanded(
          child: Obx(() {
            final needsEmptyRow = items.isEmpty ||
                (items.last['key']?.toString().isNotEmpty == true ||
                    items.last['description']?.toString().isNotEmpty == true);

            if (needsEmptyRow) {
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

            final reqId = controller.currentRequestId.value ?? 'req';

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                final isLast = idx == items.length - 1;

                return EventRowItem(
                  key: ValueKey('${reqId}_event_row_${item['id'] ?? idx}'),
                  item: item,
                  index: idx,
                  isLast: isLast,
                  requestId: reqId,
                  onKeyChanged: (val) {
                    final newItems = List<Map<String, dynamic>>.from(items);
                    newItems[idx]['key'] = val;
                    items.value = newItems;
                    onChanged();
                  },
                  onEnabledChanged: (val) {
                    final newItems = List<Map<String, dynamic>>.from(items);
                    newItems[idx]['enabled'] = val;
                    items.value = newItems;
                    onChanged();
                  },
                  onDescChanged: (val) {
                    final newItems = List<Map<String, dynamic>>.from(items);
                    newItems[idx]['description'] = val;
                    items.value = newItems;
                    onChanged();
                  },
                  onDelete: () {
                    final newItems = List<Map<String, dynamic>>.from(items);
                    newItems.removeAt(idx);
                    items.value = newItems;
                    onChanged();
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
