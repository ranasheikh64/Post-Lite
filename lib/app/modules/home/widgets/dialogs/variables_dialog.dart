import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

void showVariablesDialog(BuildContext context, dynamic collection, WorkspaceController workspaceController) {
    final RxList<Map<String, dynamic>> variables = <Map<String, dynamic>>[].obs;
    
    if (collection['variables'] != null) {
      variables.value = List<Map<String, dynamic>>.from(
        (collection['variables'] as List).map((v) => Map<String, dynamic>.from(v))
      );
    }
    
    if (variables.isEmpty) {
      variables.add({'key': '', 'value': '', 'enabled': true});
    }

    Get.defaultDialog(
      title: 'Folder Variables: ${collection['name']}',
      content: SizedBox(
        width: 500,
        height: 300,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Define variables here. Use them in requests with {{variable_name}} syntax.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: variables.length,
                  itemBuilder: (context, index) {
                    final variable = variables[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: variable['enabled'] ?? true,
                            onChanged: (val) {
                              variable['enabled'] = val;
                              variables[index] = variable;
                            },
                          ),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: TextEditingController(text: variable['key'])..selection = TextSelection.collapsed(offset: (variable['key'] ?? '').length),
                              decoration: const InputDecoration(
                                hintText: 'Key',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                variable['key'] = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: TextEditingController(text: variable['value'])..selection = TextSelection.collapsed(offset: (variable['value'] ?? '').length),
                              decoration: const InputDecoration(
                                hintText: 'Value',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                variable['value'] = val;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              variables.removeAt(index);
                              if (variables.isEmpty) {
                                variables.add({'key': '', 'value': '', 'enabled': true});
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  variables.add({'key': '', 'value': '', 'enabled': true});
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Variable'),
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        final cleanedVariables = variables.where((v) => 
          v['key'] != null && v['key'].toString().trim().isNotEmpty
        ).toList();
        
        workspaceController.updateCollectionVariables(collection['_id'], cleanedVariables);
        Get.back();
      },
    );
  }
