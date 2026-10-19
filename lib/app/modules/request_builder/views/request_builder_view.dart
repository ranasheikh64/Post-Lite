import 'package:flutter/material.dart';
import '../widgets/response_panel.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import '../controllers/request_builder_controller.dart';
import 'websocket_builder_view.dart';
import 'socketio_builder_view.dart';
import '../../../widgets/interactive_tooltip.dart';
import '../widgets/raw_body_editor.dart';
import '../widgets/dynamic_table_view.dart';
import '../widgets/request_top_bar.dart';

class RequestBuilderView extends GetView<RequestBuilderController> {
  const RequestBuilderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RequestTopBar(),
        Expanded(
          child: Obx(() {
            if (controller.requestKind.value == 'websocket') {
              return WebSocketBuilderView(
                key: ValueKey(controller.currentRequestId.value ?? 'new_request'),
              );
            } else if (controller.requestKind.value == 'socketio') {
              return SocketIOBuilderView(
                key: ValueKey(controller.currentRequestId.value ?? 'new_request'),
              );
            }
            return _buildHttpRequestBuilder(context);
          }),
        ),
      ],
    );
  }

  Widget _buildHttpRequestBuilder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2030),
                      border: Border.all(color: const Color(0xFF2E3148)),
                      borderRadius: BorderRadius.circular(8),
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
                              return Obx(() {
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
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: hoverWidgets,
                                  ),
                                  child: textField,
                                );
                              });
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
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6C37),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
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
                                indicatorColor: Color(0xFFFF6C37),
                                indicatorSize: TabBarIndicatorSize.label,
                                indicatorWeight: 2,
                                labelColor: Color(0xFFFF6C37),
                                unselectedLabelColor: Color(0xFF666980),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                tabs: [
                                  Tab(text: 'Docs'),
                                  Tab(text: 'Params'),
                                  Tab(text: 'Auth'),
                                  Tab(text: 'Headers'),
                                  Tab(text: 'Body'),
                                  Tab(text: 'Scripts'),
                                  Tab(text: 'Settings'),
                                ],
                              ),
                              const Divider(height: 1, color: Color(0xFF2A2D3E)),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    DocsView(),
                                    DynamicTableView(
                                      title: 'Query Params',
                                      items: controller.queryParams,
                                      onChanged: controller.syncParamsToUrl,
                                    ),
                                    _AuthView(),
                                    DynamicTableView(
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
                            height: 20,
                            width: double.infinity,
                            color: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Full-width divider line
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: const Color(0xFF2A2D3E),
                                ),
                                // Drag handle pill
                                Container(
                                  width: 56,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252840),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: const Color(0xFF3A3E5C),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      size: 16,
                                      color: Color(0xFF7B80A0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Response Section
                      const Expanded(
                        child: ResponsePanel(),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      );
  }

  Color _getMethodColor(String method) {
    return AppTheme.getMethodColor(method);
  }
}

class DocsView extends StatelessWidget {
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
            fillColor: Colors.grey[900]?.withOpacity(0.5),
            filled: true,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFFE65100).withOpacity(0.3),
                width: 1.5,
              ),
            ),
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
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auth Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.authType.value,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white54,
                        ),
                        dropdownColor: const Color(0xFF2A2D3E),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'inherit',
                            child: Text('Inherit auth from parent'),
                          ),
                          DropdownMenuItem(
                            value: 'none',
                            child: Text('No Auth'),
                          ),
                          DropdownMenuItem(
                            value: 'bearer',
                            child: Text('Bearer Token'),
                          ),
                          DropdownMenuItem(
                            value: 'basic',
                            child: Text('Basic Auth'),
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
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              if (controller.authType.value == 'bearer') {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bearer Token',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The authorization header will be automatically generated when you send the request.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Token',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(
                                '${controller.currentRequestId.value}_bearer',
                              ),
                              initialValue:
                                  controller.authConfig['token'] ?? '',
                              onChanged: (val) {
                                final newConfig = Map<String, dynamic>.from(
                                  controller.authConfig,
                                );
                                newConfig['token'] = val;
                                controller.authConfig.value = newConfig;
                              },
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Token',
                                hintStyle: TextStyle(color: Colors.grey[700]),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey[800]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey[800]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: const Color(
                                      0xFFE65100,
                                    ).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              } else if (controller.authType.value == 'basic') {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Auth',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The authorization header will be automatically generated when you send the request.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Username',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(
                                '${controller.currentRequestId.value}_basic_username',
                              ),
                              initialValue:
                                  controller.authConfig['username'] ?? '',
                              onChanged: (val) {
                                final newConfig = Map<String, dynamic>.from(
                                  controller.authConfig,
                                );
                                newConfig['username'] = val;
                                controller.authConfig.value = newConfig;
                              },
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Username',
                                hintStyle: TextStyle(color: Colors.grey[700]),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey[800]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey[800]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: const Color(
                                      0xFFE65100,
                                    ).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(
                                '${controller.currentRequestId.value}_basic_password',
                              ),
                              initialValue:
                                  controller.authConfig['password'] ?? '',
                              obscureText: true,
                              onChanged: (val) {
                                final newConfig = Map<String, dynamic>.from(
                                  controller.authConfig,
                                );
                                newConfig['password'] = val;
                                controller.authConfig.value = newConfig;
                              },
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.grey[700]),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey[800]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey[800]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: const Color(
                                      0xFFE65100,
                                    ).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 48, color: Colors.grey[800]),
                    const SizedBox(height: 16),
                    Text(
                      'This request is using ${controller.authType.value} auth',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
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
                  _buildRadio(
                    controller,
                    'urlencoded',
                    'x-www-form-urlencoded',
                  ),
                  _buildRadio(controller, 'raw', 'raw'),
                  _buildRadio(controller, 'binary', 'binary'),
                  _buildRadio(controller, 'graphql', 'GraphQL'),

                  if (controller.bodyType.value == 'raw') ...[
                    const SizedBox(width: 16),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: const [
                          'text',
                          'json',
                          'html',
                          'xml',
                          'javascript',
                        ].contains(controller.bodyFormat.value.toLowerCase())
                            ? controller.bodyFormat.value.toLowerCase()
                            : 'json',
                        dropdownColor: const Color(0xFF242736),
                        style: const TextStyle(
                          color: Color(0xFFFF6C37),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFFF6C37),
                          size: 18,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'text',
                            child: Text('Text', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'json',
                            child: Text('JSON', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'html',
                            child: Text('HTML', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'xml',
                            child: Text('XML', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'javascript',
                            child: Text('JavaScript', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            controller.bodyFormat.value = val;
                            controller.hasUnsavedChanges.value = true;
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: Obx(() {
            if (controller.bodyType.value == 'raw' ||
                controller.bodyType.value == 'graphql') {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: RawBodyEditor(
                  controller: controller,
                  bodyFormat: controller.bodyFormat.value,
                ),
              );
            } else if (controller.bodyType.value == 'form-data') {
              return DynamicTableView(
                items: controller.formData,
                title: 'Form Data',
                onChanged: () => controller.hasUnsavedChanges.value = true,
              );
            } else if (controller.bodyType.value == 'x-www-form-urlencoded' ||
                controller.bodyType.value == 'urlencoded') {
              return DynamicTableView(
                items: controller.urlEncodedData,
                title: 'URL Encoded',
                onChanged: () => controller.hasUnsavedChanges.value = true,
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
