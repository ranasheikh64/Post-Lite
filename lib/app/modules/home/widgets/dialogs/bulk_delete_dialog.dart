import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

void showBulkDeleteDialog(BuildContext context, WorkspaceController workspaceController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${workspaceController.selectedCollectionIds.length + workspaceController.selectedRequestIds.length} selected items?\n\nDeleting folders will also delete all their nested folders and requests.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              workspaceController.bulkDeleteSelected();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
