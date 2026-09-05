import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/socket_controller.dart';

class SocketIOBuilderView extends StatefulWidget {
  const SocketIOBuilderView({Key? key}) : super(key: key);

  @override
  _SocketIOBuilderViewState createState() => _SocketIOBuilderViewState();
}

class _SocketIOBuilderViewState extends State<SocketIOBuilderView> {
  final SocketController socketController = Get.put(SocketController());
  final RequestBuilderController reqController =
      Get.find<RequestBuilderController>();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController eventController = TextEditingController();
  final RxDouble topHeight = 400.0.obs;

  @override
  void dispose() {
    socketController.disconnect();
    Get.delete<SocketController>();
    super.dispose();
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
              ),
              stringStyle: TextStyle(
                color: Color(0xFFA6E22E),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              intStyle: TextStyle(
                color: Color(0xFFFD971F),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              doubleStyle: TextStyle(
                color: Color(0xFFFD971F),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              boolStyle: TextStyle(
                color: Color(0xFFAE81FF),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
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
      socketController.connectSocketIO(reqController.url.value, _getHeaders());
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
              Obx(
                () => Text(
                  '${reqController.currentPath.value} > ${reqController.currentRequestId.value == null
                      ? "New Socket.io Request"
                      : reqController.url.value.split("/").last.isEmpty
                      ? "Unnamed Socket.io Request"
                      : reqController.url.value.split("/").last}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'IO',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey[800],
                        width: 1,
                        indent: 6,
                        endIndent: 6,
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
                              horizontal: 12,
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
                height: 40,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: socketController.isConnected.value
                          ? Colors.red
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
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
                  if (h > constraints.maxHeight - 150)
                    h = constraints.maxHeight - 150;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Box: Composer
                      SizedBox(
                        height: h,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[800]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
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
                                      'Message',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: messageController,
                                          maxLines: null,
                                          expands: true,
                                          textAlignVertical:
                                              TextAlignVertical.top,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                          decoration: const InputDecoration(
                                            hoverColor: Colors.transparent,
                                            filled: false,
                                            hintText: 'Enter JSON payload...',
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: TextField(
                                              controller: eventController,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              decoration: const InputDecoration(
                                                hoverColor: Colors.transparent,
                                                filled: false,
                                                hintText: 'Event name',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                              ),
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
                                                        socketController
                                                            .sendMessage(
                                                              messageController
                                                                  .text,
                                                              eventName:
                                                                  eventController
                                                                      .text,
                                                            );
                                                        messageController
                                                            .clear();
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
                      ),

                      // Draggable Divider
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            topHeight.value += details.delta.dy;
                          },
                          child: Container(
                            height: 16,
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                height: 4,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
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
                                                    Text(
                                                      'Event: ${msg.eventName}',
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.orangeAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
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
