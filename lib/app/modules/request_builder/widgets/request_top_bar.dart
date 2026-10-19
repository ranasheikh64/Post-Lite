import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';
import 'code_snippet_dialog.dart';
import 'request_tabs_list.dart';
import 'top_bar_auto_save_chip.dart';
import 'top_bar_tab_scroll_buttons.dart';

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
              const TopBarTabScrollButtons(),
              const TopBarAutoSaveChip(),
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
