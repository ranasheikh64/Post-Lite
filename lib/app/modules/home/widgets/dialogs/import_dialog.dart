import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

void showImportDialog(BuildContext context, WorkspaceController workspaceController) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Postman Collection'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: textController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste Postman Collection JSON here...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final text = textController.text;
                Get.back(); // close the text input dialog FIRST
                workspaceController.importPostmanCollection(text);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
