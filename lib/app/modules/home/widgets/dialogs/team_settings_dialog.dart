import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workspace_controller.dart';

String _avatarInitials(Map member) {
  final name = member['user']['name'] as String? ?? '';
  final email = member['user']['email'] as String? ?? '';
  final source = name.isNotEmpty ? name : email;
  final parts = source.trim().split(RegExp(r'[\s@.]'));
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  if (source.isNotEmpty) return source[0].toUpperCase();
  return '?';
}

void showTeamSettingsDialog(BuildContext context, WorkspaceController workspaceController) {
  final wsId = workspaceController.selectedWorkspaceId.value;
  if (wsId == null) return;
  final ws = workspaceController.workspaces.firstWhere((w) => w['_id'] == wsId, orElse: () => null);
  if (ws == null) return;

  final emailController = TextEditingController();
  String selectedRole = 'viewer';
  bool isInviting = false;

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final members = (ws['members'] as List).toList();

        return Dialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline, color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ws['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Manage team members',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close, color: Colors.white54, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF2E2E2E), height: 1),

                // ── Invite Row ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite member',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF3A3A3A)),
                              ),
                              child: TextField(
                                controller: emailController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Email address',
                                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hoverColor: Colors.transparent,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3A3A3A)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedRole,
                                isDense: true,
                                dropdownColor: const Color(0xFF2A2A2A),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                items: ['admin', 'editor', 'viewer']
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedRole = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF2E2E2E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFF3A3A3A)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: isInviting ? null : () async {
                                if (emailController.text.trim().isEmpty) return;
                                setState(() => isInviting = true);
                                await workspaceController.addWorkspaceMember(
                                    wsId, emailController.text.trim(), selectedRole);
                                emailController.clear();
                                final updated = workspaceController.workspaces
                                    .firstWhere((w) => w['_id'] == wsId, orElse: () => null);
                                if (updated != null) {
                                  members..clear()..addAll(updated['members'] as List);
                                }
                                setState(() => isInviting = false);
                              },
                              child: isInviting
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
                                  : const Text('Invite', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Members Section ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${members.length}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Members list
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No members yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index] as Map;
                        final role = member['role'] as String? ?? 'viewer';
                        final name = member['user']['name'] as String?
                            ?? member['user']['email'] ?? 'Unknown';
                        final email = member['user']['email'] as String? ?? '';
                        final initials = _avatarInitials(member);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E2E2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name & email
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Role dropdown
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: role,
                                  isDense: true,
                                  dropdownColor: const Color(0xFF2A2A2A),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 16),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  items: ['admin', 'editor', 'viewer']
                                      .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(r, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (val) async {
                                    if (val == null) return;
                                    await workspaceController.updateWorkspaceMemberRole(
                                        wsId, member['user']['_id'] as String, val);
                                    final updated = workspaceController.workspaces
                                        .firstWhere((w) => w['_id'] == wsId, orElse: () => null);
                                    if (updated != null) {
                                      setState(() {
                                        members..clear()..addAll(updated['members'] as List);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Remove button
                              InkWell(
                                onTap: () async {
                                  await workspaceController.removeWorkspaceMember(
                                      wsId, member['user']['_id'] as String);
                                  final updated = workspaceController.workspaces
                                      .firstWhere((w) => w['_id'] == wsId, orElse: () => null);
                                  if (updated != null) {
                                    setState(() {
                                      members..clear()..addAll(updated['members'] as List);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.close, color: Colors.white.withOpacity(0.3), size: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2E2E2E), height: 1),

                // ── Footer ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    children: [
                      if (workspaceController.userRoleInWorkspace.value == 'owner')
                        InkWell(
                          onTap: () {
                            workspaceController.deleteWorkspace(wsId);
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Delete team',
                              style: TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        );
      },
    ),
  );
}