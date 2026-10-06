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

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: animation,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 550,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune, color: Color(0xFF1E88E5), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${collection['name']} Variables',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Use {{variable_name}} syntax in your requests.',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  // List
                  Expanded(
                    child: Obx(
                      () => ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: variables.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final variable = variables[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2D3E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.03)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: variable['enabled'] ?? true,
                                  activeColor: const Color(0xFFF97316), // matching app theme orange
                                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  onChanged: (val) {
                                    variable['enabled'] = val;
                                    variables[index] = variable;
                                  },
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: TextEditingController(text: variable['key'])..selection = TextSelection.collapsed(offset: (variable['key'] ?? '').length),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      hintText: 'Key',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    ),
                                    onChanged: (val) {
                                      variable['key'] = val;
                                    },
                                  ),
                                ),
                                Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: TextEditingController(text: variable['value'])..selection = TextSelection.collapsed(offset: (variable['value'] ?? '').length),
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Value',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    ),
                                    onChanged: (val) {
                                      variable['value'] = val;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                                  hoverColor: Colors.red.withOpacity(0.1),
                                  splashRadius: 16,
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

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191A23),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            variables.add({'key': '', 'value': '', 'enabled': true});
                          },
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF1E88E5)),
                          label: const Text('Add Variable', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final cleanedVariables = variables.where((v) => 
                                  v['key'] != null && v['key'].toString().trim().isNotEmpty
                                ).toList();
                                
                                workspaceController.updateCollectionVariables(collection['_id'], cleanedVariables);
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
