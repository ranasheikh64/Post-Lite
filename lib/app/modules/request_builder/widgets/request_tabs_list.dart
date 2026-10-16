import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';
import 'request_tab_item.dart';

class RequestTabsList extends StatelessWidget {
  const RequestTabsList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Obx(() {
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
            scrollController: controller.tabsScrollController,
            buildDefaultDragHandles: false,
            itemCount: controller.openRequests.length,
            onReorder: controller.reorderRequests,
            itemBuilder: (context, index) {
              final req = controller.openRequests[index];
              final reqId = req['_id']?.toString() ?? '';
              final isActive = reqId == controller.currentRequestId.value;
              final isUnsaved = controller.isTabUnsaved(reqId);

              return ReorderableDragStartListener(
                key: ValueKey(reqId),
                index: index,
                child: RequestTabItem(
                  request: req,
                  isActive: isActive,
                  isUnsaved: isUnsaved,
                  onTap: () => controller.loadRequest(
                    req,
                    path: 'Recent > ${req['name']}',
                  ),
                  onClose: () => controller.closeRequestTab(
                    reqId,
                    context: context,
                  ),
                  onSecondaryTap: (details) {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                      ),
                      items: const [
                        PopupMenuItem(value: 'close_others', child: Text('Close other tabs', style: TextStyle(fontSize: 13))),
                        PopupMenuItem(value: 'close_right', child: Text('Close tabs to the right', style: TextStyle(fontSize: 13))),
                        PopupMenuItem(value: 'close_left', child: Text('Close tabs to the left', style: TextStyle(fontSize: 13))),
                      ],
                      color: const Color(0xFF2A2D3E),
                    ).then((value) {
                      if (value == 'close_others') {
                        controller.closeOtherRequests(reqId, context: context);
                      } else if (value == 'close_right') {
                        controller.closeRequestsToRight(reqId, context: context);
                      } else if (value == 'close_left') {
                        controller.closeRequestsToLeft(reqId, context: context);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
