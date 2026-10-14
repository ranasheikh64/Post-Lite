import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/socket_controller.dart';
import 'package:postmanclone/app/modules/request_builder/views/request_builder_view.dart'; // For DocsView and DynamicTableView
import 'package:postmanclone/app/modules/request_builder/widgets/events_table_view.dart'; // For EventsTableView
import '../widgets/syntax_highlighting_controller.dart';
import '../widgets/beautify_button.dart';
import '../widgets/code_formatter.dart';
import '../widgets/comment_toggle_helper.dart';

class SocketIOBuilderView extends StatefulWidget {
  const SocketIOBuilderView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SocketIOBuilderViewState createState() => _SocketIOBuilderViewState();
}

class CommentIntent extends Intent {
  const CommentIntent();
}

class _SocketIOBuilderViewState extends State<SocketIOBuilderView> {
  final RequestBuilderController reqController =
      Get.find<RequestBuilderController>();
  late final SyntaxHighlightingController messageController =
      SyntaxHighlightingController(format: 'json');
  final TextEditingController eventController = TextEditingController();
  final RxDouble topHeight = 400.0.obs;
  final RxBool isAck = false.obs;
  bool _isBeautified = false;
  Timer? _beautifyTimer;

  String _extractRaw(dynamic bodyVal) {
    if (bodyVal == null) return '';
    if (bodyVal is Map && bodyVal['raw'] != null) {
      return _extractRaw(bodyVal['raw']);
    }
    return bodyVal.toString();
  }
  
  List<String> savedEvents = [];
  final FocusNode _eventFocusNode = FocusNode();

  late final String requestTag;
  late final SocketController socketController;

  Future<void> _loadSavedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        savedEvents = prefs.getStringList('socket_events') ?? [];
      });
    }
  }

  Future<void> _saveEvent(String eventName) async {
    if (eventName.isEmpty) return;
    if (!savedEvents.contains(eventName)) {
      savedEvents.add(eventName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('socket_events', savedEvents);
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
    final reqId = reqController.currentRequestId.value;
    requestTag = reqId != null && reqId.isNotEmpty ? reqId : 'new_socketio_request';
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
    
    // Load saved event name
    final socketConfig = reqController.socketConfig;
    if (socketConfig.containsKey('lastEventName')) {
      eventController.text = socketConfig['lastEventName'].toString();
    }
    
    // Save on change
    messageController.addListener(() {
      reqController.body.value = messageController.text;
    });
    
    eventController.addListener(() {
      final config = Map<String, dynamic>.from(reqController.socketConfig);
      config['lastEventName'] = eventController.text;
      reqController.socketConfig.value = config;
    });
  }

  void _toggleComment() {
    final updated = CommentToggleHelper.toggle(messageController.value);
    if (updated != null) {
      setState(() => messageController.value = updated);
      reqController.body.value = updated.text;
      reqController.hasUnsavedChanges.value = true;
    }
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

  @override
  void dispose() {
    _beautifyTimer?.cancel();
    messageController.dispose();
    eventController.dispose();
    _eventFocusNode.dispose();
    super.dispose();
  }

  Widget _buildMessageContent(String data) {
    if (data.trim().startsWith('{') || data.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(data);
        final formattedJson = const JsonEncoder.withIndent('  ').convert(decoded);
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text('JSON Payload', style: TextStyle(color: Colors.grey, fontSize: 12)),
            initiallyExpanded: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectionArea(
                  child: Text(
                    formattedJson,
                    style: const TextStyle(
                      color: Color(0xFFA6E22E),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (_) {}
    }
    return SelectableText(
      data,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    );
  }

  String _resolveVariables(String text) {
    if (text.isEmpty || !text.contains('{{')) return text;
    try {
      final workspaceController = Get.find<WorkspaceController>();
      final variables = workspaceController.getVariablesForRequest(reqController.currentRequestId.value ?? '');
      String resolvedText = text;
      variables.forEach((key, value) {
        resolvedText = resolvedText.replaceAll('{{$key}}', value);
      });
      return resolvedText;
    } catch (_) {
      return text;
    }
  }

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {};
    for (var h in reqController.headers) {
      if (h['enabled'] == true && h['key'].toString().isNotEmpty) {
        headers[_resolveVariables(h['key'])] = _resolveVariables(h['value']);
      }
    }
    return headers;
  }

  Map<String, String> _getQueryParams() {
    final Map<String, String> queryParams = {};
    for (var q in reqController.queryParams) {
      if (q['enabled'] == true && q['key'].toString().isNotEmpty) {
        queryParams[_resolveVariables(q['key'])] = _resolveVariables(q['value']);
      }
    }
    return queryParams;
  }

  void _connect() {
    if (socketController.isConnected.value) {
      socketController.disconnect();
    } else {
      socketController.connectSocketIO(_resolveVariables(reqController.url.value), _getHeaders(), _getQueryParams());
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Obx(
                  () => Text(
                    '${reqController.currentPath.value} > ${reqController.currentRequestId.value == null
                        ? "New Socket.io Request"
                        : reqController.url.value.split("/").last.isEmpty
                        ? "Unnamed Socket.io Request"
                        : reqController.url.value.split("/").last}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                          color: const Color(0xFFFF6C37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'IO',
                          style: TextStyle(
                            color: Color(0xFFFF6C37),
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
                            hintText: 'http:// or https://',
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
                          length: 6,
                          initialIndex: 4, // Default to Message
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
                                  Tab(text: 'Events'),
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
                                      onChanged: reqController.syncParamsToUrl,
                                    ),
                                    DynamicTableView(
                                      items: reqController.headers,
                                      title: 'Headers',
                                      onChanged:
                                          () =>
                                              reqController
                                                  .hasUnsavedChanges
                                                  .value = true,
                                    ),
                                    EventsTableView(
                                      items: reqController.socketEvents,
                                      onChanged:
                                          () =>
                                              reqController
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
                                                                  'Enter JSON payload...',
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
                                                      Row(
                                                        children: [
                                                          Obx(() => Checkbox(
                                                            value: isAck.value,
                                                            onChanged: (val) {
                                                              if (val != null) isAck.value = val;
                                                            },
                                                          )),
                                                          const Text('Ack', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                                          const SizedBox(width: 8),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width: 150,
                                                        child: RawAutocomplete<String>(
                                                          textEditingController: eventController,
                                                          focusNode: _eventFocusNode,
                                                          optionsBuilder: (TextEditingValue textEditingValue) {
                                                            if (textEditingValue.text.isEmpty) {
                                                              return savedEvents;
                                                            }
                                                            return savedEvents.where((String option) {
                                                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                                            });
                                                          },
                                                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                                            return TextField(
                                                              controller: textEditingController,
                                                              focusNode: focusNode,
                                                              style: const TextStyle(fontSize: 13),
                                                              decoration: const InputDecoration(
                                                                hoverColor: Colors.transparent,
                                                                filled: false,
                                                                hintText: 'Event name',
                                                                border: OutlineInputBorder(),
                                                                isDense: true,
                                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                              ),
                                                              onSubmitted: (String value) {
                                                                onFieldSubmitted();
                                                              },
                                                            );
                                                          },
                                                          optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                                                            return Align(
                                                              alignment: Alignment.topLeft,
                                                              child: Material(
                                                                elevation: 4.0,
                                                                color: const Color(0xFF2C2C2C),
                                                                borderRadius: BorderRadius.circular(4),
                                                                child: ConstrainedBox(
                                                                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 150),
                                                                  child: ListView.builder(
                                                                    padding: EdgeInsets.zero,
                                                                    itemCount: options.length,
                                                                    itemBuilder: (BuildContext context, int index) {
                                                                      final String option = options.elementAt(index);
                                                                      return InkWell(
                                                                        onTap: () {
                                                                          onSelected(option);
                                                                        },
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(8.0),
                                                                          child: Text(option, style: const TextStyle(fontSize: 13, color: Colors.white)),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
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
                                                                    _saveEvent(eventController.text);
                                                                    
                                                                    final rawText = messageController.text;
                                                                    final cleanText = rawText
                                                                        .split('\n')
                                                                        .where((line) => !line.trimLeft().startsWith('//'))
                                                                        .join('\n');
                                                                        
                                                                    socketController
                                                                        .sendMessage(
                                                                          cleanText,
                                                                          eventName:
                                                                              eventController
                                                                                  .text,
                                                                          withAck: isAck.value,
                                                                        );
                                                                  }
                                                                }
                                                              : null,
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 24,
                                                                  vertical: 12,
                                                                ),
                                                            backgroundColor: const Color(
                                                              0xFF2563EB,
                                                            ),
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(4),
                                                            ),
                                                          ),
                                                          child: const Text('Send'),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                color: Colors.grey[900],
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Response',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () =>
                                          socketController.clearMessages(),
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
                                      final msg =
                                          socketController.messages[index];
                                      final timeStr = DateFormat(
                                        'HH:mm:ss',
                                      ).format(msg.timestamp);
                                      return Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[800]!,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (msg.isSystem)
                                              Icon(
                                                msg.content.startsWith('Connected')
                                                    ? Icons.check_circle_outline
                                                    : Icons.info_outline,
                                                color: msg.content.startsWith('Connected')
                                                    ? Colors.green
                                                    : Colors.grey,
                                                size: 16,
                                              )
                                            else
                                              Icon(
                                                msg.isSent
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                color: msg.isSent
                                                    ? Colors.orange
                                                    : Colors.blue,
                                                size: 16,
                                              ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (msg.eventName != null &&
                                                      msg.eventName!.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF2E3B51).withValues(alpha: 0.5),
                                                        border: Border.all(color: const Color(0xFF3F4F6A)),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        msg.eventName!,
                                                        style: const TextStyle(
                                                          color: Color(0xFF6DA2FF),
                                                          fontSize: 12,
                                                          fontFamily: 'monospace'
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(height: 4),
                                                  _buildMessageContent(
                                                    msg.content,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              timeStr,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                              ),
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
