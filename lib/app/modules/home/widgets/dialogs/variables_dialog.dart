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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Folder Variables: ${collection['name']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        content: SizedBox(
          width: 550,
          height: 350,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Define variables here. Use them in requests with {{variable_name}} syntax.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
                              activeColor: const Color(0xFFE65100),
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              onChanged: (val) {
                                variable['enabled'] = val;
                                variables[index] = variable;
                              },
                            ),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: TextEditingController(text: variable['key'])..selection = TextSelection.collapsed(offset: (variable['key'] ?? '').length),
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Key',
                                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2C),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: const Color(0xFFE65100).withOpacity(0.5), width: 1.5)),
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
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Value',
                                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2C),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: const Color(0xFFE65100).withOpacity(0.5), width: 1.5)),
                                ),
                                onChanged: (val) {
                                  variable['value'] = val;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFFE65100)),
                  label: const Text('Add Variable', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                ),
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
              final cleanedVariables = variables.where((v) => 
                v['key'] != null && v['key'].toString().trim().isNotEmpty
              ).toList();
              
              workspaceController.updateCollectionVariables(collection['_id'], cleanedVariables);
              Get.back();
            },
            child: const Text('Save Variables', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
