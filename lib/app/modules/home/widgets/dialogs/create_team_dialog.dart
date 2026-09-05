import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

void showCreateTeamDialog(BuildContext context, WorkspaceController workspaceController) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Team Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                workspaceController.createWorkspace(nameController.text);
                Get.back();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
