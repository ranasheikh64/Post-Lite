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
            backgroundColor: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Transfer Collection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Move this collection to a different team or your personal workspace. This will move all its requests and data.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select target workspace:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    dropdownColor: const Color(0xFF2C2C2C),
                    icon: const Icon(Icons.expand_more, size: 16, color: Colors.grey),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: const Color(0xFFE65100).withOpacity(0.5), width: 1.5),
                      ),
                    ),
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
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  workspaceController.transferCollection(collection['_id'], targetWorkspaceId);
                  Get.back();
                },
                child: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        }
      ),
    );
  }
