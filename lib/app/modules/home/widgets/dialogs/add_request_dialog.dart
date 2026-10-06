import 'package:flutter/material.dart';
import '../../controllers/workspace_controller.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';

void showAddRequestDialog(
  BuildContext context, {
  String? defaultCollectionId,
  required WorkspaceController workspaceController,
  String defaultKind = 'http', // 'http', 'websocket', 'socketio'
}) {
  final nameController = TextEditingController();
  String selectedMethod = 'GET';
  String? selectedCollectionId = defaultCollectionId ??
      (workspaceController.collections.isNotEmpty ? workspaceController.collections[0]['_id'] : null);

  String getTitleText() {
    switch (defaultKind) {
      case 'websocket':
        return 'New WebSocket Request';
      case 'socketio':
        return 'New Socket.IO Request';
      default:
        return 'New HTTP Request';
    }
  }

  IconData getTitleIcon() {
    switch (defaultKind) {
      case 'websocket':
        return Icons.swap_calls;
      case 'socketio':
        return Icons.sensors;
      default:
        return Icons.http;
    }
  }

  Color getTitleColor() {
    switch (defaultKind) {
      case 'websocket':
        return Colors.purple;
      case 'socketio':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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
            content: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  width: 450,
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                color: getTitleColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(getTitleIcon(), color: getTitleColor(), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                getTitleText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
                      
                      // Body
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (defaultCollectionId == null && workspaceController.collections.isNotEmpty) ...[
                              const Text('Collection', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2D3E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF2A2D3E),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    value: selectedCollectionId,
                                    items: workspaceController.collections.map((c) => DropdownMenuItem<String>(
                                      value: c['_id'],
                                      child: Text(c['name']),
                                    )).toList(),
                                    onChanged: (val) => setState(() => selectedCollectionId = val),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (defaultCollectionId == null && workspaceController.collections.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Please create a collection first.', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                              
                            const Text('Request Details', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (defaultKind == 'http') ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2D3E),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        dropdownColor: const Color(0xFF2A2D3E),
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                                        value: selectedMethod,
                                        items: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'].map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m, style: TextStyle(color: AppTheme.getMethodColor(m), fontWeight: FontWeight.bold, fontSize: 14)),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => selectedMethod = val);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2D3E),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller: nameController,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Enter request name',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      autofocus: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                          mainAxisAlignment: MainAxisAlignment.end,
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
                              onPressed: selectedCollectionId == null
                                  ? null
                                  : () {
                                      if (nameController.text.isNotEmpty) {
                                        workspaceController.createRequest(
                                          selectedCollectionId!,
                                          nameController.text,
                                          selectedMethod,
                                          defaultKind,
                                        );
                                        Navigator.of(context).pop();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Create Request', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
