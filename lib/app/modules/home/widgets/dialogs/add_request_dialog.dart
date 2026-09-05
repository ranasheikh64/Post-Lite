import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
void showAddRequestDialog(
    BuildContext context, {
    String? defaultCollectionId, required WorkspaceController workspaceController,
  }) {
    final nameController = TextEditingController();
    String selectedKind = 'http';
    String selectedMethod = 'GET';
    String? selectedCollectionId =
        defaultCollectionId ??
        (workspaceController.collections.isNotEmpty
            ? workspaceController.collections[0]['_id']
            : null);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (defaultCollectionId == null &&
                      workspaceController.collections.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Collection',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCollectionId,
                      items: workspaceController.collections
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c['_id'],
                              child: Text(c['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCollectionId = val),
                    ),
                  if (defaultCollectionId == null &&
                      workspaceController.collections.isEmpty)
                    const Text(
                      'Please create a collection first.',
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedKind,
                            items: [
                              DropdownMenuItem(value: 'http', child: Text('HTTP', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'websocket', child: Text('WebSocket', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'socketio', child: Text('Socket.IO', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedKind = val;
                                  if (val != 'http') selectedMethod = 'GET'; // Reset method if not http
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedKind == 'http') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMethod,
                              items:
                                  [
                                        'GET',
                                        'POST',
                                        'PUT',
                                        'PATCH',
                                        'DELETE',
                                        'HEAD',
                                        'OPTIONS',
                                      ]
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(
                                            m,
                                            style: TextStyle(
                                              color: AppTheme.getMethodColor(m),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => selectedMethod = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: 'Request Name',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedCollectionId == null
                      ? null
                      : () {
                          if (nameController.text.isNotEmpty) {
                            workspaceController.createRequest(
                              selectedCollectionId!,
                              nameController.text,
                              selectedMethod,
                              selectedKind,
                            );
                            Get.back();
                          }
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
