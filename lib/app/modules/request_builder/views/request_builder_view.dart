import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:postmanclone/app/widgets/custom_json_viewer.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';
import '../controllers/request_builder_controller.dart';
import 'websocket_builder_view.dart';
import 'socketio_builder_view.dart';
import '../../../widgets/interactive_tooltip.dart';
import 'package:file_picker/file_picker.dart';
import 'package:postmanclone/app/widgets/variable_autocomplete.dart';
import '../widgets/code_snippet_dialog.dart';

class RequestBuilderView extends GetView<RequestBuilderController> {
  const RequestBuilderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.requestKind.value == 'websocket') {
        return const WebSocketBuilderView();
      } else if (controller.requestKind.value == 'socketio') {
        return SocketIOBuilderView(
          key: ValueKey(controller.currentRequestId.value ?? 'new_request'),
        );
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
                Expanded(
                  child: Obx(() {
                    if (controller.openRequests.isEmpty) {
                      return const Text(
                        'No active requests',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      );
                    }
                    return Listener(
                      onPointerDown: (event) {
                        if (kIsWeb && event.buttons == kSecondaryMouseButton) {
                          BrowserContextMenu.disableContextMenu();
                        }
                      },
                      onPointerUp: (event) {
                        if (kIsWeb && event.buttons == kSecondaryButton) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            BrowserContextMenu.enableContextMenu();
                          });
                        }
                      },
                      child: SizedBox(
                        height: 36,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          buildDefaultDragHandles: false,
                          itemCount: controller.openRequests.length,
                          onReorder: (oldIndex, newIndex) {
                            controller.reorderRequests(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final req = controller.openRequests[index];
                            final isActive =
                                req['_id'] == controller.currentRequestId.value;
                            return ReorderableDragStartListener(
                              key: ValueKey(req['_id']),
                              index: index,
                              child: GestureDetector(
                                onSecondaryTapDown: (details) {
                                  showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                    ),
                                    items: const [
                                      PopupMenuItem(
                                        value: 'close_others',
                                        child: Text(
                                          'Close other tabs',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'close_right',
                                        child: Text(
                                          'Close tabs to the right',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'close_left',
                                        child: Text(
                                          'Close tabs to the left',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                    color: const Color(0xFF2A2D3E),
                                  ).then((value) {
                                    if (value == 'close_others') {
                                      controller.closeOtherRequests(req['_id']);
                                    } else if (value == 'close_right') {
                                      controller.closeRequestsToRight(
                                        req['_id'],
                                      );
                                    } else if (value == 'close_left') {
                                      controller.closeRequestsToLeft(
                                        req['_id'],
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF2A2D3E)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: InkWell(
                                    onTap: () => controller.loadRequest(
                                      req,
                                      path: 'Recent > ${req['name']}',
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            req['method'] ?? 'GET',
                                            style: TextStyle(
                                              color: AppTheme.getMethodColor(
                                                req['method'] ?? 'GET',
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            req['name'] ?? 'Unnamed',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.white
                                                  : Colors.white54,
                                              fontSize: 13,
                                              fontWeight: isActive
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              controller.openRequests
                                                  .removeWhere(
                                                    (r) =>
                                                        r['_id'] == req['_id'],
                                                  );
                                              if (isActive) {
                                                if (controller
                                                    .openRequests
                                                    .isNotEmpty) {
                                                  final lastReq = controller
                                                      .openRequests
                                                      .last;
                                                  controller.loadRequest(
                                                    lastReq,
                                                    path:
                                                        'Recent > ${lastReq['name']}',
                                                  );
                                                } else {
                                                  controller
                                                          .currentRequestId
                                                          .value =
                                                      null;
                                                }
                                              }
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
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
                    IconButton(
                      tooltip: 'Code Snippet',
                      onPressed: () {
                        showCodeSnippetSidePanel(context, controller);
                      },
                      icon: const Icon(Icons.code, size: 18),
                      color: Colors.grey[400],
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
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: controller
                                                      .responseData
                                                      .value,
                                                ),
                                              );
                                              CustomSnackbar.show(
                                                title: 'Copied',
                                                message:
                                                    'Response copied to clipboard',
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.copy,
                                              size: 14,
                                            ),
                                            tooltip: 'Copy Response',
                                            color: Colors.grey,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            splashRadius: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
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
        final decoded = jsonDecode(data);
        return CustomJsonViewer(jsonObj: decoded);
      } catch (_) {
        // Fallback to text if parsing fails
      }
    }
    return SingleChildScrollView(
      child: SelectableText(
        data,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
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
                        value: controller.bodyFormat.value,
                        dropdownColor: const Color(0xFF2B2B2B),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                        ),
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
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: Obx(() {
            if (controller.bodyType.value == 'raw' ||
                controller.bodyType.value == 'graphql') {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: _RawBodyEditor(controller: controller),
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

class DynamicTableView extends StatelessWidget {
  final String title;
  final RxList<Map<String, dynamic>> items;
  final VoidCallback onChanged;

  const DynamicTableView({
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - 160;
              final columnWidth = availableWidth > 0
                  ? availableWidth / 3
                  : 100.0;

              return SingleChildScrollView(
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
                      const DataColumn(
                        label: SizedBox(width: 32, child: Text('')),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: columnWidth,
                          child: const Text('Key'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: columnWidth,
                          child: const Text('Value'),
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
                            Checkbox(
                              value: item['enabled'] ?? true,
                              onChanged: (val) {
                                final newItems =
                                    List<Map<String, dynamic>>.from(items);
                                newItems[idx]['enabled'] = val;
                                items.value = newItems;
                                onChanged();
                              },
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: VariableAutocomplete(
                                      key: ValueKey('${title}_key_$uniqueId'),
                                      initialValue: item['key'],
                                      onChanged: (val) {
                                        final newItems =
                                            List<Map<String, dynamic>>.from(
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
                                        hintStyle: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: const Color(
                                              0xFFE65100,
                                            ).withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (title == 'Form Data') ...[
                                    const SizedBox(width: 4),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: item['type'] ?? 'text',
                                        dropdownColor: const Color(0xFF2B2B2B),
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'text',
                                            child: Text('Text'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'file',
                                            child: Text('File'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            final newItems =
                                                List<Map<String, dynamic>>.from(
                                                  items,
                                                );
                                            newItems[idx]['type'] = val;
                                            if (val == 'file') {
                                              newItems[idx]['value'] = '';
                                            }
                                            items.value = newItems;
                                            onChanged();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child:
                                  (title == 'Form Data' &&
                                      item['type'] == 'file')
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['value']
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true
                                                ? item['value']
                                                      .toString()
                                                      .split('/')
                                                      .last
                                                : 'Select File',
                                            style: TextStyle(
                                              color:
                                                  item['value']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.file_upload,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () async {
                                            final result =
                                                await FilePicker.pickFiles();
                                            if (result.single.path != null) {
                                              final newItems =
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(items);
                                              newItems[idx]['value'] =
                                                  result.single.path;
                                              items.value = newItems;
                                              onChanged();
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  : Tooltip(
                                      message: (item['value']?.toString() ?? '')
                                          .replaceAllMapped(
                                            RegExp(r'.{1,60}'),
                                            (match) => '${match.group(0)}\n',
                                          )
                                          .trim(),
                                      waitDuration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey[800]!,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      textStyle: const TextStyle(
                                        color: Color(
                                          0xFFCE9178,
                                        ), // VS Code orange/string color
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                        height: 1.5,
                                      ),
                                      child: VariableAutocomplete(
                                        key: ValueKey('${title}_val_$uniqueId'),
                                        initialValue: item['value'],
                                        onChanged: (val) {
                                          final newItems =
                                              List<Map<String, dynamic>>.from(
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
                                          hintStyle: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: BorderSide(
                                              color: const Color(
                                                0xFFE65100,
                                              ).withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: TextFormField(
                                key: ValueKey(
                                  '${controller.currentRequestId.value}_${title}_desc_$uniqueId',
                                ),
                                initialValue: item['description'],
                                onChanged: (val) {
                                  final newItems =
                                      List<Map<String, dynamic>>.from(items);
                                  newItems[idx]['description'] = val;
                                  items.value = newItems;
                                  onChanged();
                                },
                                decoration: InputDecoration(
                                  hoverColor: Colors.transparent,
                                  filled: false,
                                  hintText: 'Description',
                                  hintStyle: TextStyle(color: Colors.grey[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
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
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
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
                                          List<Map<String, dynamic>>.from(
                                            items,
                                          );
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RawBodyEditor extends StatefulWidget {
  final RequestBuilderController controller;
  const _RawBodyEditor({Key? key, required this.controller}) : super(key: key);

  @override
  State<_RawBodyEditor> createState() => _RawBodyEditorState();
}

class _RawBodyEditorState extends State<_RawBodyEditor> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.body.value is String
          ? widget.controller.body.value
          : '',
    );
  }

  @override
  void didUpdateWidget(_RawBodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentVal = widget.controller.body.value is String
        ? widget.controller.body.value
        : '';
    if (currentVal != _textController.text) {
      _textController.text = currentVal;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _toggleComment() {
    final text = _textController.text;
    final selection = _textController.selection;

    if (selection.baseOffset == -1 || selection.extentOffset == -1) return;

    final start = selection.start;
    final end = selection.end;

    int lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    int lineEnd = end;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }

    final selectedLinesText = text.substring(lineStart, lineEnd);
    final lines = selectedLinesText.split('\n');

    bool allCommented =
        lines.isNotEmpty &&
        lines.every((line) => line.trimLeft().startsWith('//'));

    final newLines = lines.map((line) {
      if (allCommented) {
        final idx = line.indexOf('//');
        if (idx != -1) {
          final afterComment = line.substring(idx + 2);
          return line.substring(0, idx) +
              (afterComment.startsWith(' ')
                  ? afterComment.substring(1)
                  : afterComment);
        }
        return line;
      } else {
        return '// $line';
      }
    }).toList();

    final newLinesText = newLines.join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, newLinesText);
    final lengthDiff = newLinesText.length - selectedLinesText.length;

    setState(() {
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset:
              start +
              (start == lineStart && allCommented
                  ? -3
                  : (start == lineStart && !allCommented ? 3 : 0)),
          extentOffset: end + lengthDiff,
        ),
      );
    });

    widget.controller.body.value = newText;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash, control: true):
            _toggleComment,
        const SingleActivator(LogicalKeyboardKey.slash, meta: true):
            _toggleComment,
      },
      child: Focus(
        autofocus: true,
        child: TextFormField(
          key: ValueKey(
            '${widget.controller.currentRequestId.value}_body_field',
          ),
          controller: _textController,
          onChanged: (val) => widget.controller.body.value = val,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }
}
