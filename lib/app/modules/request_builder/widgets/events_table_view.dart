import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/widgets/variable_autocomplete.dart';

class EventsTableView extends StatelessWidget {
  final RxList<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  const EventsTableView({
    Key? key,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Events',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - 120;
              final columnWidth = availableWidth > 0 ? availableWidth / 2 : 100.0;

              return SingleChildScrollView(
                child: Obx(() {
                  // Ensure one empty row at the bottom safely
                  bool needsEmptyRow = items.isEmpty ||
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

                  return DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    horizontalMargin: 16,
                    columnSpacing: 16,
                    dividerThickness: 1,
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 13),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: columnWidth,
                          child: const Text('Events'),
                        ),
                      ),
                      const DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text('Listen'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: columnWidth,
                          child: const Text('Description'),
                        ),
                      ),
                      const DataColumn(
                        label: SizedBox(width: 32, child: Text('')),
                      ),
                    ],
                    rows: items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final isLast = idx == items.length - 1;
                      final uniqueId = item['id'] ?? idx.toString();

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: VariableAutocomplete(
                                key: ValueKey('${controller.currentRequestId.value}_events_key_$uniqueId'),
                                initialValue: item['key']?.toString() ?? '',
                                onChanged: (val) {
                                  final newItems = List<Map<String, dynamic>>.from(items);
                                  newItems[idx]['key'] = val;
                                  items.value = newItems;
                                  onChanged();
                                },
                                decoration: InputDecoration(
                                  hoverColor: Colors.transparent,
                                  filled: false,
                                  hintText: 'Add event',
                                  hintStyle: TextStyle(color: Colors.grey[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Colors.transparent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: const Color(0xFFE65100).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 60,
                              child: Transform.scale(
                                scale: 0.7,
                                child: CupertinoSwitch(
                                  value: item['enabled'] ?? true,
                                  activeColor: const Color(0xFF2563EB),
                                  onChanged: (val) {
                                    final newItems = List<Map<String, dynamic>>.from(items);
                                    newItems[idx]['enabled'] = val;
                                    items.value = newItems;
                                    onChanged();
                                  },
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: TextField(
                                controller: TextEditingController(text: item['description']?.toString() ?? '')..selection = TextSelection.collapsed(offset: (item['description']?.toString() ?? '').length),
                                onChanged: (val) {
                                  final newItems = List<Map<String, dynamic>>.from(items);
                                  newItems[idx]['description'] = val;
                                  items.value = newItems;
                                  onChanged();
                                },
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hoverColor: Colors.transparent,
                                  filled: false,
                                  hintText: 'Add description',
                                  hintStyle: TextStyle(color: Colors.grey[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Colors.transparent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: const Color(0xFFE65100).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 32,
                              child: isLast
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      splashRadius: 12,
                                      onPressed: () {
                                        final newItems = List<Map<String, dynamic>>.from(items);
                                        newItems.removeAt(idx);
                                        items.value = newItems;
                                        onChanged();
                                      },
                                    ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
