import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import '../../controllers/workspace_controller.dart';

void showRenameRequestDialog(
  BuildContext context,
  Map<String, dynamic> request,
  WorkspaceController workspaceController,
) {
  final TextEditingController nameController = TextEditingController(text: request['name'] ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2D3E),
        title: const Text('Rename Request', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter new name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != request['name']) {
                workspaceController.renameRequest(request['_id'], newName);
              }
              Get.back();
            },
            child: const Text('Rename'),
          ),
        ],
      );
    },
  );
}
