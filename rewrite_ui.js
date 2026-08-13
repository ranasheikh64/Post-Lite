const fs = require('fs');

const path = 'lib/app/modules/request_builder/request_builder_view.dart';
let content = fs.readFileSync(path, 'utf8');

const newTabs = `                                  _DocsView(),
                                  _DynamicTableView(
                                    title: 'Query Params',
                                    items: controller.queryParams,
                                    onChanged: controller.syncParamsToUrl,
                                  ),
                                  _AuthView(),
                                  _DynamicTableView(
                                    title: 'Headers',
                                    items: controller.headers,
                                    onChanged: () {},
                                  ),
                                  _BodyView(),
                                  const Center(child: Text('Scripts Editor (Coming Soon)', style: TextStyle(color: Colors.grey))),
                                  const Center(child: Text('Settings (Coming Soon)', style: TextStyle(color: Colors.grey))),`;

content = content.replace(/const Center\(child: Text\('Documentation.*?Settings \(Coming Soon\)', style: TextStyle\(color: Colors.grey\)\)\),/s, newTabs);

const newClasses = `class _DocsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => TextFormField(
        key: ValueKey(controller.currentRequestId.value),
        initialValue: controller.docs.value,
        onChanged: (val) => controller.docs.value = val,
        maxLines: null,
        expands: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Add documentation here (Markdown supported)...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
        ),
      )),
    );
  }
}

class _AuthView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey[800]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Auth Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.authType.value,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2B2B2B),
                    items: const [
                      DropdownMenuItem(value: 'inherit', child: Text('Inherit auth from parent', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'none', child: Text('No Auth', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'bearer', child: Text('Bearer Token', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'basic', child: Text('Basic Auth', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.authType.value = val;
                    },
                  ),
                ),
              )),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              if (controller.authType.value == 'bearer') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bearer Token', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 100, child: Text('Token', style: TextStyle(color: Colors.grey, fontSize: 13))),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('\${controller.currentRequestId.value}_bearer'),
                            initialValue: controller.authConfig['token'] ?? '',
                            onChanged: (val) {
                              final newConfig = Map<String, dynamic>.from(controller.authConfig);
                              newConfig['token'] = val;
                              controller.authConfig.value = newConfig;
                            },
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Token',
                              isDense: true,
                              contentPadding: const EdgeInsets.all(8),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Center(child: Text('This request is using \${controller.authType.value} auth', style: const TextStyle(color: Colors.grey)));
            }),
          ),
        ),
      ],
    );
  }
}

class _BodyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Obx(() => Row(
            children: [
              _buildRadio(controller, 'none', 'none'),
              _buildRadio(controller, 'form-data', 'form-data'),
              _buildRadio(controller, 'urlencoded', 'x-www-form-urlencoded'),
              _buildRadio(controller, 'raw', 'raw'),
              _buildRadio(controller, 'binary', 'binary'),
              _buildRadio(controller, 'graphql', 'GraphQL'),
              
              if (controller.bodyType.value == 'raw') ...[
                const SizedBox(width: 16),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.bodyFormat.value,
                    dropdownColor: const Color(0xFF2B2B2B),
                    style: const TextStyle(color: Colors.blue, fontSize: 13),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue, size: 16),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text')),
                      DropdownMenuItem(value: 'json', child: Text('JSON')),
                      DropdownMenuItem(value: 'html', child: Text('HTML')),
                      DropdownMenuItem(value: 'xml', child: Text('XML')),
                      DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.bodyFormat.value = val;
                    },
                  ),
                ),
              ],
            ],
          )),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: Obx(() {
            if (controller.bodyType.value == 'raw' || controller.bodyType.value == 'graphql') {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  key: ValueKey('\${controller.currentRequestId.value}_body'),
                  initialValue: controller.body.value is String ? controller.body.value : '',
                  onChanged: (val) => controller.body.value = val,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              );
            }
            return Center(child: Text('\${controller.bodyType.value} editor coming soon', style: const TextStyle(color: Colors.grey)));
          }),
        ),
      ],
    );
  }

  Widget _buildRadio(RequestBuilderController controller, String value, String label) {
    final isSelected = controller.bodyType.value == value;
    return GestureDetector(
      onTap: () => controller.bodyType.value = value,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
                 size: 16, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _DynamicTableView extends StatelessWidget {
  final String title;
  final RxList<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  const _DynamicTableView({required this.title, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Obx(() {
              // Ensure one empty row at the bottom safely
              bool needsEmptyRow = items.isEmpty || (items.last['key']?.toString().isNotEmpty == true || items.last['value']?.toString().isNotEmpty == true);
              if (needsEmptyRow) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  items.add({'key': '', 'value': '', 'description': '', 'enabled': true, 'id': DateTime.now().millisecondsSinceEpoch.toString()});
                });
              }
              
              return DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                horizontalMargin: 16,
                columnSpacing: 16,
                dividerThickness: 1,
                headingTextStyle: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                dataTextStyle: const TextStyle(fontSize: 13),
                columns: const [
                  DataColumn(label: SizedBox(width: 32, child: Text(''))),
                  DataColumn(label: Expanded(child: Text('Key'))),
                  DataColumn(label: Expanded(child: Text('Value'))),
                  DataColumn(label: Expanded(child: Text('Description'))),
                  DataColumn(label: SizedBox(width: 32, child: Text(''))),
                ],
                rows: items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isLast = idx == items.length - 1;
                  final uniqueId = item['id'] ?? idx.toString();
                  
                  return DataRow(cells: [
                    DataCell(
                      Checkbox(
                        value: item['enabled'] ?? true,
                        onChanged: (val) {
                          final newItems = List<Map<String, dynamic>>.from(items);
                          newItems[idx]['enabled'] = val;
                          items.value = newItems;
                          onChanged();
                        },
                      ),
                    ),
                    DataCell(TextFormField(
                      key: ValueKey('\${controller.currentRequestId.value}_\${title}_key_$uniqueId'),
                      initialValue: item['key'],
                      onChanged: (val) {
                        final newItems = List<Map<String, dynamic>>.from(items);
                        newItems[idx]['key'] = val;
                        items.value = newItems;
                        onChanged();
                      },
                      decoration: InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.grey[700]), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    )),
                    DataCell(TextFormField(
                      key: ValueKey('\${controller.currentRequestId.value}_\${title}_val_$uniqueId'),
                      initialValue: item['value'],
                      onChanged: (val) {
                        final newItems = List<Map<String, dynamic>>.from(items);
                        newItems[idx]['value'] = val;
                        items.value = newItems;
                        onChanged();
                      },
                      decoration: InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.grey[700]), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    )),
                    DataCell(TextFormField(
                      key: ValueKey('\${controller.currentRequestId.value}_\${title}_desc_$uniqueId'),
                      initialValue: item['description'],
                      onChanged: (val) {
                        final newItems = List<Map<String, dynamic>>.from(items);
                        newItems[idx]['description'] = val;
                        items.value = newItems;
                        onChanged();
                      },
                      decoration: InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: Colors.grey[700]), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    )),
                    DataCell(
                      !isLast ? IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final newItems = List<Map<String, dynamic>>.from(items);
                          newItems.removeAt(idx);
                          items.value = newItems;
                          onChanged();
                        },
                      ) : const SizedBox(),
                    ),
                  ]);
                }).toList(),
              );
            }),
          ),
        ),
      ],
    );
  }
}
`;

content = content.replace(/class _ParamsTableView extends StatelessWidget \{.*?\}/s, newClasses);

fs.writeFileSync(path, content, 'utf8');
