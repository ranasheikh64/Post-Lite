import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import 'add_collection_dialog.dart';

void showAddRequestDialog(
  BuildContext context, {
  String? defaultCollectionId,
  required WorkspaceController workspaceController,
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
            backgroundColor: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Create New Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (defaultCollectionId == null &&
                      workspaceController.collections.isNotEmpty) ...[
                    const Text(
                      'Select Collection',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: const Color(0xFFE65100).withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                      value: selectedCollectionId,
                      items: [
                        ...workspaceController.collections.map(
                          (c) => DropdownMenuItem<String>(
                            value: c['_id'],
                            child: Text(c['name']),
                          ),
                        ),
                        const DropdownMenuItem<String>(
                          value: '__new_collection__',
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFFE65100),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create New Collection',
                                style: TextStyle(
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        if (val == '__new_collection__') {
                          final newId = await showAddCollectionDialog(context, workspaceController);
                          if (newId != null) {
                            setState(() => selectedCollectionId = newId);
                          } else {
                            setState(() {});
                          }
                        } else {
                          setState(() => selectedCollectionId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (defaultCollectionId == null &&
                      workspaceController.collections.isEmpty)
                    const Text(
                      'Please create a collection first.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF2C2C2C),
                            value: selectedKind,
                            items: const [
                              DropdownMenuItem(
                                value: 'http',
                                child: Text(
                                  'HTTP',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'websocket',
                                child: Text(
                                  'WebSocket',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'socketio',
                                child: Text(
                                  'Socket.IO',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedKind = val;
                                  if (val != 'http') selectedMethod = 'GET';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedKind == 'http') ...[
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: const Color(0xFF2C2C2C),
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
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => selectedMethod = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Request Name',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: const Color(0xFFE65100).withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  elevation: 0,
                ),
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
                child: const Text(
                  'Create Request',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
