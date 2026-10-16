import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';
import 'code_snippet_dialog.dart';
import 'request_tabs_list.dart';

class RequestTopBar extends StatelessWidget {
  const RequestTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: RequestTabsList()),
          Row(
            children: [
              Obx(() {
                if (controller.openRequests.length <= 1) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222533),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Scroll tabs left',
                        child: InkWell(
                          onTap: controller.scrollTabsLeft,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Colors.white70),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 16, color: Colors.white12),
                      Tooltip(
                        message: 'Scroll tabs right',
                        child: InkWell(
                          onTap: controller.scrollTabsRight,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () => controller.saveChanges(),
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[300],
                  side: BorderSide(color: Colors.grey[800]!),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Code Snippet',
                onPressed: () => showCodeSnippetSidePanel(context, controller),
                icon: const Icon(Icons.code, size: 18),
                color: Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
