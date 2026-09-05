import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

void showTransferDialog(BuildContext context, dynamic collection, WorkspaceController workspaceController) {
    String? targetWorkspaceId = workspaceController.selectedWorkspaceId.value;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Transfer Collection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select target workspace:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: targetWorkspaceId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Personal Workspace'),
                    ),
                    ...workspaceController.workspaces.map((ws) => DropdownMenuItem<String?>(
                      value: ws['_id'],
                      child: Text(ws['name']),
                    )),
                  ],
                  onChanged: (val) => setState(() => targetWorkspaceId = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  workspaceController.transferCollection(collection['_id'], targetWorkspaceId);
                  Get.back();
                },
                child: const Text('Transfer'),
              ),
            ],
          );
        }
      ),
    );
  }
