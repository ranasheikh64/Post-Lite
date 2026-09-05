import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

void showTeamSettingsDialog(BuildContext context, WorkspaceController workspaceController) {
    final wsId = workspaceController.selectedWorkspaceId.value;
    if (wsId == null) return;
    final ws = workspaceController.workspaces.firstWhere((w) => w['_id'] == wsId, orElse: () => null);
    if (ws == null) return;

    final emailController = TextEditingController();
    String selectedRole = 'viewer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final members = (ws['members'] as List).toList();
          return AlertDialog(
            title: Text('Manage Team: ${ws['name']}'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invite Member', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            hintText: 'User Email',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedRole,
                        items: ['admin', 'editor', 'viewer']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (emailController.text.isNotEmpty) {
                            await workspaceController.addWorkspaceMember(wsId, emailController.text, selectedRole);
                            emailController.clear();
                            // Refresh ws reference
                            final updatedWs = workspaceController.workspaces.firstWhere((w) => w['_id'] == wsId, orElse: () => null);
                            if (updatedWs != null) {
                              setState(() {
                                members.clear();
                                members.addAll(updatedWs['members']);
                              });
                            }
                          }
                        },
                        child: const Text('Invite'),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Members', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        // ignore: unused_local_variable
                        final isMe = false; // We can improve this check
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(member['user']['name'] ?? member['user']['email'] ?? 'Unknown'),
                          subtitle: Text(member['user']['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: member['role'] ?? 'viewer',
                                items: ['admin', 'editor', 'viewer']
                                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (val) async {
                                  if (val != null) {
                                    await workspaceController.updateWorkspaceMemberRole(wsId, member['user']['_id'], val);
                                    final updatedWs = workspaceController.workspaces.firstWhere((w) => w['_id'] == wsId, orElse: () => null);
                                    if (updatedWs != null) {
                                      setState(() {
                                        members.clear();
                                        members.addAll(updatedWs['members']);
                                      });
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                onPressed: () async {
                                  await workspaceController.removeWorkspaceMember(wsId, member['user']['_id']);
                                  final updatedWs = workspaceController.workspaces.firstWhere((w) => w['_id'] == wsId, orElse: () => null);
                                  if (updatedWs != null) {
                                    setState(() {
                                      members.clear();
                                      members.addAll(updatedWs['members']);
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            actions: [
              if (workspaceController.userRoleInWorkspace.value == 'owner')
                TextButton(
                  onPressed: () {
                    workspaceController.deleteWorkspace(wsId);
                    Get.back();
                  },
                  child: const Text('Delete Team', style: TextStyle(color: Colors.red)),
                ),
              TextButton(onPressed: () => Get.back(), child: const Text('Close')),
            ],
          );
        }
      ),
    );
  }
