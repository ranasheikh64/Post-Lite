import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/socket_controller.dart';
import 'package:postmanclone/app/modules/request_builder/views/request_builder_view.dart'; // For DocsView
import '../widgets/dynamic_table_view.dart';
import '../widgets/syntax_highlighting_controller.dart';
import '../widgets/beautify_button.dart';
import '../widgets/code_formatter.dart';
import '../widgets/comment_toggle_helper.dart';

class WebSocketBuilderView extends StatefulWidget {
  const WebSocketBuilderView({super.key});

  @override
  State<WebSocketBuilderView> createState() => _WebSocketBuilderViewState();
}

class _WebSocketBuilderViewState extends State<WebSocketBuilderView> {
  late final SocketController socketController;
  final RequestBuilderController reqController =
      Get.find<RequestBuilderController>();
  late final SyntaxHighlightingController messageController =
      SyntaxHighlightingController(format: 'json');
  final RxDouble topHeight = 400.0.obs;
  bool _isBeautified = false;
  Timer? _beautifyTimer;

  String _extractRaw(dynamic bodyVal) {
    if (bodyVal == null) return '';
    if (bodyVal is Map && bodyVal['raw'] != null) {
      return _extractRaw(bodyVal['raw']);
    }
    return bodyVal.toString();
  }

  @override
  void initState() {
    super.initState();
    final reqId = reqController.currentRequestId.value;
    final requestTag =
        reqId != null && reqId.isNotEmpty ? reqId : 'new_websocket_request';
    if (Get.isRegistered<SocketController>(tag: requestTag)) {
      socketController = Get.find<SocketController>(tag: requestTag);
    } else {
      socketController = Get.put(SocketController(), tag: requestTag);
    }

    // Load saved payload
    final rawText = _extractRaw(reqController.body.value);
    if (rawText.isNotEmpty) {
      messageController.text = rawText;
    }

    // Sync message changes to request body for persistence and auto-save
    messageController.addListener(_onMessageChanged);
  }

  void _onMessageChanged() {
    reqController.body.value = messageController.text;
  }

  @override
  void dispose() {
    _beautifyTimer?.cancel();
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    super.dispose();
  }

  void _beautify() {
    final raw = messageController.text;
    if (raw.trim().isEmpty) return;
    try {
      final formatted = CodeFormatter.format(text: raw, format: 'json');
      if (formatted != null && formatted != raw) {
        _beautifyTimer?.cancel();
        setState(() {
          messageController.text = formatted;
          _isBeautified = true;
        });
        reqController.body.value = formatted;
        reqController.hasUnsavedChanges.value = true;
        _beautifyTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isBeautified = false);
        });
      }
    } catch (_) {}
  }

  void _toggleComment() {
    final updated = CommentToggleHelper.toggle(messageController.value);
    if (updated != null) {
      setState(() => messageController.value = updated);
      reqController.body.value = updated.text;
      reqController.hasUnsavedChanges.value = true;
    }
  }

  Widget _buildMessageContent(String data) {
    if (data.trim().startsWith('{') || data.trim().startsWith('[')) {
      try {
        jsonDecode(data);
        return SelectionArea(
          child: JsonView.string(
            data,
            theme: const JsonViewTheme(
              backgroundColor: Colors.transparent,
              defaultTextStyle: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              viewType: JsonViewType.collapsible,
              keyStyle: TextStyle(color: Color(0xFF66D9EF), fontSize: 13, fontFamily: 'monospace'),
              stringStyle: TextStyle(color: Color(0xFFA6E22E), fontSize: 13, fontFamily: 'monospace'),
              intStyle: TextStyle(color: Color(0xFFFD971F), fontSize: 13, fontFamily: 'monospace'),
              doubleStyle: TextStyle(color: Color(0xFFFD971F), fontSize: 13, fontFamily: 'monospace'),
              boolStyle: TextStyle(color: Color(0xFFAE81FF), fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        );
      } catch (_) {}
    }
    return SelectableText(
      data,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    );
  }

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {};
    for (var h in reqController.headers) {
      if (h['enabled'] == true && h['key'].toString().isNotEmpty) {
        headers[h['key']] = h['value'];
      }
    }
    return headers;
  }

  void _connect() {
    if (socketController.isConnected.value) {
      socketController.disconnect();
    } else {
      socketController.connectWebSocket(reqController.url.value, _getHeaders());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Breadcrumb & Actions Row
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() => Text(
                  '${reqController.currentPath.value} > ${reqController.currentRequestId.value == null ? "New WS Request" : reqController.url.value.split("/").last.isEmpty ? "Unnamed WS Request" : reqController.url.value.split("/").last}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                )),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => reqController.saveChanges(),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[300],
                      side: BorderSide(color: Colors.grey[800]!),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2030),
                    border: Border.all(color: const Color(0xFF2D3142)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9D4EDD).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'WS',
                          style: TextStyle(
                            color: Color(0xFFB57EDC),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey[800],
                        width: 16,
                        indent: 8,
                        endIndent: 8,
                      ),
                      Expanded(
                        child: TextField(
                          controller: reqController.urlController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hoverColor: Colors.transparent,
                            filled: false,
                            hintText: 'ws:// or wss://',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: socketController.isConnected.value
                          ? const Color(0xFFE53935)
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: _connect,
                    child: socketController.isConnecting.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            socketController.isConnected.value
                                ? 'Disconnect'
                                : 'Connect',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error Message if any
        Obx(() {
          if (socketController.connectionError.value.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Error: ${socketController.connectionError.value}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox();
        }),

        // Main Layout (Messages History and Composer)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Obx(() {
                  double h = topHeight.value;
                  if (h < 150) h = 150;
                  if (h > constraints.maxHeight - 150) {
                    h = constraints.maxHeight - 150;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Box: Tabs and Composer
                      SizedBox(
                        height: h,
                        child: DefaultTabController(
                          length: 5,
                          initialIndex: 3, // Default to Message
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                dividerColor: Colors.transparent,
                                indicatorColor: Color(0xFFFF6C37),
                                indicatorWeight: 2,
                                labelColor: Color(0xFFFF6C37),
                                unselectedLabelColor: Colors.grey,
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                tabs: [
                                  Tab(text: 'Docs'),
                                  Tab(text: 'Params'),
                                  Tab(text: 'Headers'),
                                  Tab(text: 'Message'),
                                  Tab(text: 'Settings'),
                                ],
                              ),
                              const Divider(height: 1, color: Colors.white10),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    DocsView(),
                                    DynamicTableView(
                                      items: reqController.queryParams,
                                      title: 'Query Params',
                                      onChanged: () => reqController
                                          .hasUnsavedChanges
                                          .value = true,
                                    ),
                                    DynamicTableView(
                                      items: reqController.headers,
                                      title: 'Headers',
                                      onChanged: () => reqController
                                          .hasUnsavedChanges
                                          .value = true,
                                    ),
                                    // Message Composer
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF2D3142),
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF181A25),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                topRight: Radius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Payload',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFA0A5B5),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                BeautifyButton(
                                                  onPressed: _beautify,
                                                  isBeautified: _isBeautified,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: CallbackShortcuts(
                                                      bindings: {
                                                        const SingleActivator(
                                                          LogicalKeyboardKey
                                                              .slash,
                                                          control: true,
                                                        ): _toggleComment,
                                                        const SingleActivator(
                                                          LogicalKeyboardKey
                                                              .slash,
                                                          meta: true,
                                                        ): _toggleComment,
                                                        const SingleActivator(
                                                          LogicalKeyboardKey
                                                              .keyB,
                                                          control: true,
                                                          shift: true,
                                                        ): _beautify,
                                                        const SingleActivator(
                                                          LogicalKeyboardKey
                                                              .keyB,
                                                          meta: true,
                                                          shift: true,
                                                        ): _beautify,
                                                      },
                                                      child: TextField(
                                                        controller:
                                                            messageController,
                                                        onChanged: (val) {
                                                          if (_isBeautified) {
                                                            setState(
                                                              () =>
                                                                  _isBeautified =
                                                                      false,
                                                            );
                                                          }
                                                        },
                                                        maxLines: null,
                                                        expands: true,
                                                        textAlignVertical:
                                                            TextAlignVertical
                                                                .top,
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'monospace',
                                                          fontSize: 13,
                                                          color: Color(
                                                            0xFFD4D4D4,
                                                          ),
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              filled: false,
                                                              hintText:
                                                                  'Enter message to send...',
                                                              border: InputBorder
                                                                  .none,
                                                              isDense: true,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Obx(
                                                        () => ElevatedButton(
                                                          onPressed:
                                                              socketController
                                                                  .isConnected
                                                                  .value
                                                              ? () {
                                                                  if (messageController
                                                                      .text
                                                                      .isNotEmpty) {
                                                                    final rawText = messageController.text;
                                                                    final cleanText = rawText
                                                                        .split('\n')
                                                                        .where((line) => !line.trimLeft().startsWith('//'))
                                                                        .join('\n');
                                                                    socketController
                                                                        .sendMessage(
                                                                          cleanText,
                                                                        );
                                                                  }
                                                                }
                                                              : null,
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          24,
                                                                      vertical:
                                                                          12,
                                                                    ),
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFFFF6C37,
                                                                    ),
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                              ),
                                                          child: const Text(
                                                            'Send',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'Settings coming soon',
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
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) {
                            topHeight.value += details.delta.dy;
                          },
                          child: Container(
                            height: 20,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Divider(height: 1, color: Colors.grey[800]),
                                Container(
                                  width: 56,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF242736),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: const Color(0xFF383B4F),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      size: 15,
                                      color: Color(0xFF9EA3C0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Box: Messages (Response)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[800]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: Colors.grey[900],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Response', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                      onPressed: () => socketController.clearMessages(),
                                      tooltip: 'Clear Messages',
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Obx(() {
                                  if (socketController.messages.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No messages yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: socketController.messages.length,
                                    itemBuilder: (context, index) {
                                      final msg = socketController.messages[index];
                                      final timeStr = DateFormat('HH:mm:ss').format(msg.timestamp);
                                      return Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              msg.isSent ? Icons.arrow_upward : Icons.arrow_downward,
                                              color: msg.isSent ? Colors.green : Colors.blue,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildMessageContent(msg.content),
                                            ),
                                            Text(
                                              timeStr,
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
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
        ),
      ],
    );
  }
}
