import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/modules/home/widgets/dialogs/create_team_dialog.dart';
import 'package:postmanclone/app/modules/home/widgets/dialogs/team_settings_dialog.dart';
import 'package:postmanclone/app/modules/home/widgets/workspace_menu_item.dart';

class SidebarWorkspaceSelector extends StatelessWidget {
  final WorkspaceController workspaceController;
  const SidebarWorkspaceSelector({Key? key, required this.workspaceController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = workspaceController.selectedWorkspaceId.value;
      final currentWs = workspaceController.workspaces.firstWhereOrNull((ws) => ws['_id'] == selectedId);
      final currentName = currentWs != null ? (currentWs['name'] ?? 'Team') : 'Personal Workspace';
      final isTeam = selectedId != null;
      final canManage = workspaceController.userRoleInWorkspace.value == 'owner' ||
          workspaceController.userRoleInWorkspace.value == 'admin';

      return Container(
        height: 48,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF2A2D3E))),
        ),
        child: Row(
          children: [
            Expanded(
              child: PopupMenuButton<String?>(
                tooltip: 'Switch Workspace',
                color: const Color(0xFF222536),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF2E334D)),
                ),
                offset: const Offset(8, 44),
                onSelected: (val) {
                  if (val == '__create_team__') {
                    showCreateTeamDialog(context, workspaceController);
                  } else {
                    workspaceController.switchWorkspace(val);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String?>(
                    enabled: false,
                    height: 28,
                    child: Text(
                      'WORKSPACES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF8E92A8),
                      ),
                    ),
                  ),
                  buildWorkspaceMenuItem(
                    id: null,
                    title: 'Personal Workspace',
                    icon: Icons.person_outline,
                    isSelected: selectedId == null,
                  ),
                  ...workspaceController.workspaces.map((ws) => buildWorkspaceMenuItem(
                        id: ws['_id'] as String?,
                        title: ws['name'] ?? 'Unnamed',
                        icon: Icons.workspaces_outline,
                        isSelected: selectedId == ws['_id'],
                      )),
                  const PopupMenuDivider(height: 8),
                  const PopupMenuItem<String?>(
                    value: '__create_team__',
                    height: 36,
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF6C37)),
                        SizedBox(width: 10),
                        Text(
                          'Create New Team',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFF6C37)),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    hoverColor: Colors.white.withValues(alpha: 0.04),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.workspaces_outline, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  hoverColor: Colors.white.withValues(alpha: 0.08),
                  onTap: () {
                    if (isTeam && canManage) {
                      showTeamSettingsDialog(context, workspaceController);
                    } else {
                      showCreateTeamDialog(context, workspaceController);
                    }
                  },
                  child: Tooltip(
                    message: isTeam && canManage ? 'Manage Team' : 'Create Team',
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        isTeam ? Icons.settings_outlined : Icons.group_add_outlined,
                        size: 16,
                        color: isTeam && canManage ? Colors.white70 : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
