import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import 'request_builder_controller.dart';
import 'websocket_builder_view.dart';
import 'socketio_builder_view.dart';
import '../../widgets/interactive_tooltip.dart';

class RequestBuilderView extends StatelessWidget {
  const RequestBuilderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Put controller in memory
    final controller = Get.find<RequestBuilderController>();

    return Obx(() {
      if (controller.requestKind.value == 'websocket') {
        return const WebSocketBuilderView();
      } else if (controller.requestKind.value == 'socketio') {
        return const SocketIOBuilderView();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Breadcrumb & Actions Row
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    '${controller.currentPath.value} > ${controller.currentRequestId.value == null
                        ? "New Request"
                        : controller.url.value.split("/").last.isEmpty
                        ? "Unnamed Request"
                        : controller.url.value.split("/").last}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => controller.saveChanges(),
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[300],
                        side: BorderSide(color: Colors.grey[800]!),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[300],
                        side: BorderSide(color: Colors.grey[800]!),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // URL Bar Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Colors.grey[800]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        // Method Dropdown
                        SizedBox(
                          width: 90,
                          child: Obx(
                            () => DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.method.value,
                                isExpanded: true,
                                padding: const EdgeInsets.only(left: 12),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getMethodColor(
                                    controller.method.value,
                                  ),
                                ),
                                items:
                                    [
                                      'GET',
                                      'POST',
                                      'PUT',
                                      'PATCH',
                                      'DELETE',
                                      'HEAD',
                                      'OPTIONS',
                                    ].map((m) {
                                      return DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          m,
                                          style: TextStyle(
                                            color: _getMethodColor(m),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) =>
                                    controller.method.value = val!,
                              ),
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: Colors.grey[800],
                          width: 1,
                          indent: 6,
                          endIndent: 6,
                        ),
                        // URL Input
                        Expanded(
                          child: AnimatedBuilder(
                            animation: controller.urlController,
                            builder: (context, child) {
                              final hoverWidgets = controller
                                  .getVariableTooltipWidgets();
                              final textField = TextField(
                                controller: controller.urlController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hoverColor: Colors.transparent,
                                  filled: false,
                                  hintText: 'Enter URL or paste text',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ), // Center align text
                                  isDense: true,
                                ),
                              );

                              if (hoverWidgets.isEmpty) {
                                return textField;
                              }

                              return InteractiveTooltip(
                                popup: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: hoverWidgets,
                                ),
                                child: textField,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Postman blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: () => controller.sendRequest(),
                    child: Obx(
                      () => controller.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs and Response Area inside a LayoutBuilder for resizable split
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Obx(() {
                  double topHeight = controller.topPanelHeight.value;
                  // Constraints so it doesn't overflow or disappear
                  if (topHeight < 60) topHeight = 60;
                  if (topHeight > constraints.maxHeight - 60)
                    topHeight = constraints.maxHeight - 60;
                  if (topHeight < 60)
                    topHeight = 60; // Fallback for extremely small windows

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Section (Tabs)
                      SizedBox(
                        height: topHeight,
                        child: DefaultTabController(
                          key: ValueKey(controller.currentRequestId.value),
                          length: 7,
                          initialIndex: 4, // Default to Body tab
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                dividerColor: Colors.transparent,
                                indicatorColor: Colors.orange,
                                indicatorWeight: 2,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey,
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                tabs: [
                                  Tab(text: 'Docs'),
                                  Tab(text: 'Params'),
                                  Tab(text: 'Authorization'),
                                  Tab(text: 'Headers'),
                                  Tab(text: 'Body'),
                                  Tab(text: 'Scripts'),
                                  Tab(text: 'Settings'),
                                ],
                              ),
                              const Divider(height: 1, color: Colors.white10),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _DocsView(),
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
                                    const Center(
                                      child: Text(
                                        'Scripts Editor (Coming Soon)',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Settings (Coming Soon)',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Draggable Divider
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            controller.topPanelHeight.value += details.delta.dy;
                          },
                          child: Container(
                            height: 8, // Thicker invisible grab area
                            width: double.infinity,
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                height: 1,
                                width: double.infinity,
                                color: Colors.grey[800], // Visible thin line
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Response Section
                      Expanded(
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: controller.responseStatus.value == 0
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.rocket_launch_outlined,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Send + Get a successful response',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[800]!,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Response',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          const Text(
                                            'History',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Status: ${controller.responseStatus.value} OK',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Time: ${controller.responseTime.value} ms',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Size: ${controller.responseSize.value} B',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          TextButton.icon(
                                            onPressed: () {
                                              final nameCtrl =
                                                  TextEditingController();
                                              Get.defaultDialog(
                                                title: 'Save Response',
                                                content: TextField(
                                                  controller: nameCtrl,
                                                  decoration: const InputDecoration(
                                                    labelText:
                                                        'Response Name (e.g. 200 OK)',
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                  autofocus: true,
                                                ),
                                                textConfirm: 'Save',
                                                textCancel: 'Cancel',
                                                confirmTextColor: Colors.white,
                                                onConfirm: () {
                                                  if (nameCtrl
                                                      .text
                                                      .isNotEmpty) {
                                                    controller.saveResponse(
                                                      nameCtrl.text,
                                                    );
                                                    Get.back();
                                                  }
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.save,
                                              size: 14,
                                            ),
                                            label: const Text(
                                              'Save Response',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.blue,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: _buildResponseView(
                                          controller.responseData.value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildResponseView(String data) {
    if (data.trim().startsWith('{') || data.trim().startsWith('[')) {
      try {
        jsonDecode(data); // verify it's parseable JSON
        return SelectionArea(
          child: JsonView.string(
            data,
            theme: const JsonViewTheme(
              backgroundColor: Colors.transparent,
              defaultTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              viewType: JsonViewType.collapsible,
              keyStyle: TextStyle(
                color: Color(0xFF66D9EF),
                fontSize: 13,
                fontFamily: 'monospace',
              ), // Light blue
              stringStyle: TextStyle(
                color: Color(0xFFA6E22E),
                fontSize: 13,
                fontFamily: 'monospace',
              ), // Green
              intStyle: TextStyle(
                color: Color(0xFFFD971F),
                fontSize: 13,
                fontFamily: 'monospace',
              ), // Orange
              doubleStyle: TextStyle(
                color: Color(0xFFFD971F),
                fontSize: 13,
                fontFamily: 'monospace',
              ), // Orange
              boolStyle: TextStyle(
                color: Color(0xFFF92672),
                fontSize: 13,
                fontFamily: 'monospace',
              ), // Pink
            ),
          ),
        );
      } catch (_) {
        // Fallback to text if parsing fails
      }
    }
    return SelectableText(
      data,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    );
  }

  Color _getMethodColor(String method) {
    return AppTheme.getMethodColor(method);
  }
}

class _DocsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(
        () => TextFormField(
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
        ),
      ),
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
              const Text(
                'Auth Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Container(
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
                        DropdownMenuItem(
                          value: 'inherit',
                          child: Text(
                            'Inherit auth from parent',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'none',
                          child: Text(
                            'No Auth',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'bearer',
                          child: Text(
                            'Bearer Token',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'basic',
                          child: Text(
                            'Basic Auth',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.authType.value = val;
                      },
                    ),
                  ),
                ),
              ),
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
                    const Text(
                      'Bearer Token',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Text(
                            'Token',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                              '${controller.currentRequestId.value}_bearer',
                            ),
                            initialValue: controller.authConfig['token'] ?? '',
                            onChanged: (val) {
                              final newConfig = Map<String, dynamic>.from(
                                controller.authConfig,
                              );
                              newConfig['token'] = val;
                              controller.authConfig.value = newConfig;
                            },
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Token',
                              isDense: true,
                              contentPadding: const EdgeInsets.all(8),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Center(
                child: Text(
                  'This request is using ${controller.authType.value} auth',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.blue,
                        size: 16,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text')),
                        DropdownMenuItem(value: 'json', child: Text('JSON')),
                        DropdownMenuItem(value: 'html', child: Text('HTML')),
                        DropdownMenuItem(value: 'xml', child: Text('XML')),
                        DropdownMenuItem(
                          value: 'javascript',
                          child: Text('JavaScript'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.bodyFormat.value = val;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        )),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: Obx(() {
            if (controller.bodyType.value == 'raw' ||
                controller.bodyType.value == 'graphql') {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  key: ValueKey('${controller.currentRequestId.value}_body'),
                  initialValue: controller.body.value is String
                      ? controller.body.value
                      : '',
                  onChanged: (val) => controller.body.value = val,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              );
            }
            return Center(
              child: Text(
                '${controller.bodyType.value} editor coming soon',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRadio(
    RequestBuilderController controller,
    String value,
    String label,
  ) {
    final isSelected = controller.bodyType.value == value;
    return GestureDetector(
      onTap: () => controller.bodyType.value = value,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
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

  const _DynamicTableView({
    required this.title,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Obx(() {
              // Ensure one empty row at the bottom safely
              bool needsEmptyRow =
                  items.isEmpty ||
                  (items.last['key']?.toString().isNotEmpty == true ||
                      items.last['value']?.toString().isNotEmpty == true);
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
                headingRowHeight: 32,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                horizontalMargin: 16,
                columnSpacing: 16,
                dividerThickness: 1,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
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

                  return DataRow(
                    cells: [
                      DataCell(
                        Checkbox(
                          value: item['enabled'] ?? true,
                          onChanged: (val) {
                            final newItems = List<Map<String, dynamic>>.from(
                              items,
                            );
                            newItems[idx]['enabled'] = val;
                            items.value = newItems;
                            onChanged();
                          },
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          key: ValueKey(
                            '${controller.currentRequestId.value}_${title}_key_$uniqueId',
                          ),
                          initialValue: item['key'],
                          onChanged: (val) {
                            final newItems = List<Map<String, dynamic>>.from(
                              items,
                            );
                            newItems[idx]['key'] = val;
                            items.value = newItems;
                            onChanged();
                          },
                          decoration: InputDecoration(
                            hoverColor: Colors.transparent,
                            filled: false,
                            hintText: 'Key',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          key: ValueKey(
                            '${controller.currentRequestId.value}_${title}_val_$uniqueId',
                          ),
                          initialValue: item['value'],
                          onChanged: (val) {
                            final newItems = List<Map<String, dynamic>>.from(
                              items,
                            );
                            newItems[idx]['value'] = val;
                            items.value = newItems;
                            onChanged();
                          },
                          decoration: InputDecoration(
                            hoverColor: Colors.transparent,
                            filled: false,
                            hintText: 'Value',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          key: ValueKey(
                            '${controller.currentRequestId.value}_${title}_desc_$uniqueId',
                          ),
                          initialValue: item['description'],
                          onChanged: (val) {
                            final newItems = List<Map<String, dynamic>>.from(
                              items,
                            );
                            newItems[idx]['description'] = val;
                            items.value = newItems;
                            onChanged();
                          },
                          decoration: InputDecoration(
                            hoverColor: Colors.transparent,
                            filled: false,
                            hintText: 'Description',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      DataCell(
                        !isLast
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final newItems =
                                      List<Map<String, dynamic>>.from(items);
                                  newItems.removeAt(idx);
                                  items.value = newItems;
                                  onChanged();
                                },
                              )
                            : const SizedBox(),
                      ),
                    ],
                  );
                }).toList(),
              );
            }),
          ),
        ),
      ],
    );
  }
}
