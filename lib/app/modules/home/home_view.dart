import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/request_builder_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../request_builder/request_builder_view.dart';
import 'workspace_controller.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final WorkspaceController workspaceController = Get.put(
    WorkspaceController(),
  );
  final RequestBuilderController reqBuilder = Get.put(
    RequestBuilderController(),
  );

  void _showAddCollectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Collection Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                workspaceController.createCollection(nameController.text);
                Get.back();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Postman Collection'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: textController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste Postman Collection JSON here...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final text = textController.text;
                Get.back(); // close the text input dialog FIRST
                workspaceController.importPostmanCollection(text);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, String parentId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                workspaceController.createFolder(parentId, nameController.text);
                Get.back();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Team Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                workspaceController.createWorkspace(nameController.text);
                Get.back();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context, dynamic collection) {
    String? targetWorkspaceId = workspaceController.selectedWorkspaceId.value;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Transfer Collection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select target workspace:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
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
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  workspaceController.transferCollection(collection['_id'], targetWorkspaceId);
                  Get.back();
                },
                child: const Text('Transfer'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showTeamSettingsDialog(BuildContext context) {
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

  void _showBulkDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${workspaceController.selectedCollectionIds.length + workspaceController.selectedRequestIds.length} selected items?\n\nDeleting folders will also delete all their nested folders and requests.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              workspaceController.bulkDeleteSelected();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddRequestDialog(
    BuildContext context, {
    String? defaultCollectionId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.view_sidebar_outlined),
          tooltip: 'Toggle Sidebar',
          onPressed: workspaceController.toggleSidebar,
        ),
        title: const Text('Jronix Workspace'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(Routes.SETTINGS),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Obx(() {
            final isVisible = workspaceController.isSidebarVisible.value;
            final currentWidth = isVisible
                ? workspaceController.sidebarWidth.value
                : 0.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: currentWidth,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: workspaceController.sidebarWidth.value,
                  maxWidth: workspaceController.sidebarWidth.value,
                  alignment: Alignment.topLeft,
                  child: Container(
                    color: Theme.of(context).cardColor,
                    child: Column(
                      children: [
                        // Workspace Switcher
                        Obx(() => Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.workspaces_outline, size: 20, color: AppTheme.textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    isExpanded: true,
                                    value: workspaceController.selectedWorkspaceId.value,
                                    hint: const Text('Personal Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Personal Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      ...workspaceController.workspaces.map((ws) => DropdownMenuItem<String?>(
                                        value: ws['_id'],
                                        child: Text(ws['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      workspaceController.switchWorkspace(val);
                                    },
                                  ),
                                ),
                              ),
                              if (workspaceController.selectedWorkspaceId.value != null && (workspaceController.userRoleInWorkspace.value == 'owner' || workspaceController.userRoleInWorkspace.value == 'admin'))
                                IconButton(
                                  icon: const Icon(Icons.settings, size: 18),
                                  tooltip: 'Manage Team',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showTeamSettingsDialog(context),
                                )
                              else if (workspaceController.selectedWorkspaceId.value == null)
                                IconButton(
                                  icon: const Icon(Icons.group_add, size: 18),
                                  tooltip: 'Create Team',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showCreateTeamDialog(context),
                                )
                            ],
                          ),
                        )),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Obx(
                                  () => Text(
                                    workspaceController.isSelectionMode.value
                                        ? '${workspaceController.selectedCollectionIds.length + workspaceController.selectedRequestIds.length} selected'
                                        : 'Collections',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Obx(
                                () => Row(
                                  children: [
                                    if (workspaceController
                                        .isSelectionMode
                                        .value) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        tooltip: 'Delete Selected',
                                        onPressed: () {
                                          if (workspaceController
                                                  .selectedCollectionIds
                                                  .isNotEmpty ||
                                              workspaceController
                                                  .selectedRequestIds
                                                  .isNotEmpty) {
                                            _showBulkDeleteDialog(context);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        tooltip: 'Cancel Selection',
                                        onPressed: workspaceController
                                            .toggleSelectionMode,
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.checklist,
                                          size: 20,
                                        ),
                                        tooltip: 'Select multiple',
                                        onPressed: workspaceController
                                            .toggleSelectionMode,
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.add, size: 20),
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Add new',
                                        offset: const Offset(0, 30),
                                        onSelected: (value) {
                                          if (value == 'collection') {
                                            _showAddCollectionDialog(context);
                                          } else if (value == 'request') {
                                            _showAddRequestDialog(context);
                                          } else if (value == 'import') {
                                            _showImportDialog(context);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'collection',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.folder_outlined,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text('New Collection'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'request',
                                            child: Row(
                                              children: [
                                                Icon(Icons.http, size: 18),
                                                SizedBox(width: 8),
                                                Text('New Request'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'import',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.file_upload,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Import JSON'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Obx(() {
                            if (workspaceController.isLoading.value &&
                                workspaceController.collections.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (workspaceController.collections.isEmpty) {
                              return const Center(
                                child: Text('No collections yet.'),
                              );
                            }
                            return ListView.builder(
                              itemCount: workspaceController.collections.length,
                              itemBuilder: (context, index) {
                                return _buildCollectionNode(
                                  context,
                                  workspaceController.collections[index],
                                  workspaceController.collections,
                                  0,
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            final isVisible = workspaceController.isSidebarVisible.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isVisible ? 4.0 : 0.0,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 4.0,
                  maxWidth: 4.0,
                  alignment: Alignment.centerLeft,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        workspaceController.updateSidebarWidth(
                          details.delta.dx,
                        );
                      },
                      child: Container(
                        width: 4,
                        color: Colors.transparent,
                        child: const Center(child: VerticalDivider(width: 1)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Main Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minWidth = 500.0;
                if (constraints.maxWidth < minWidth) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: minWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: SizedBox(
                        width: minWidth,
                        child: const RequestBuilderView(),
                      ),
                    ),
                  );
                }
                return const RequestBuilderView();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionNode(
    BuildContext context,
    dynamic collection,
    List<dynamic> parentList,
    int depth, {
    String parentPath = 'Workspace',
  }) {
    final requests = collection['requests'] ?? [];
    final folders = collection['folders'] ?? [];
    final currentPath = '$parentPath > ${collection['name']}';

    return Obx(() => Dismissible(
      key: ValueKey('collection_${collection['_id']}'),
      direction: workspaceController.userRoleInWorkspace.value == 'viewer' ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDelete(
          context,
          collection['name'] ?? 'Collection',
        );
      },
      onDismissed: (direction) {
        parentList.remove(collection);
        workspaceController.collections.refresh();
        workspaceController.deleteCollection(collection['_id']);
      },
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16.0),
        leading: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (workspaceController.isSelectionMode.value)
                Checkbox(
                  value: workspaceController.selectedCollectionIds.contains(
                    collection['_id'],
                  ),
                  onChanged: (val) {
                    workspaceController.toggleCollectionSelection(
                      collection['_id'],
                    );
                  },
                ),
              Icon(
                depth == 0 ? Icons.folder_outlined : Icons.folder_open_outlined,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                collection['name'] ?? 'Unnamed',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => workspaceController.userRoleInWorkspace.value == 'viewer' 
                ? const SizedBox.shrink() 
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Add Folder',
                    splashRadius: 16,
                    onPressed: () {
                      _showAddFolderDialog(context, collection['_id']);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Add Request',
                    splashRadius: 16,
                    onPressed: () {
                      _showAddRequestDialog(
                        context,
                        defaultCollectionId: collection['_id'],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.tune,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Variables',
                    splashRadius: 16,
                    onPressed: () {
                      _showVariablesDialog(context, collection);
                    },
                  ),
                  const SizedBox(width: 8),
                  if (depth == 0) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.drive_file_move_outline,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Transfer to Team',
                      splashRadius: 16,
                      onPressed: () {
                        _showTransferDialog(context, collection);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete',
                    splashRadius: 16,
                    hoverColor: Colors.red.withOpacity(0.1),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Delete',
                        middleText: 'Delete ${collection['name']}?',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.red,
                        onConfirm: () {
                          workspaceController.deleteCollection(
                            collection['_id'],
                          );
                          Get.back();
                        },
                      );
                    },
                  ),
                ],
              )),
            ],
          ),
        ),
        children: [
          // Render sub-folders
          ...folders.map(
            (f) => _buildCollectionNode(
              context,
              f,
              folders,
              depth + 1,
              parentPath: currentPath,
            ),
          ),
          // Render requests with ReorderableListView
          if (requests.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              onReorder: (oldIndex, newIndex) {
                workspaceController.reorderRequests(
                  requests,
                  oldIndex,
                  newIndex,
                );
              },
              itemBuilder: (context, idx) {
                final req = requests[idx];
                return _buildRequestItem(
                  req,
                  requests,
                  depth,
                  ValueKey(req['_id']),
                  currentPath,
                  idx,
                );
              },
            ),
        ],
      ),
    ));
  }

  Widget _buildRequestItem(
    dynamic req,
    List<dynamic> parentList,
    int depth,
    Key key,
    String path,
    int index,
  ) {
    final savedResponses = req['savedResponses'] ?? [];
    req['isExpanded'] ??= false.obs;
    final RxBool isExpanded = req['isExpanded'];

    return Container(
      key: key,
      child: Obx(() {
        final isSelected = reqBuilder.currentRequestId.value == req['_id'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => Dismissible(
              key: ValueKey('req_dismiss_${req['_id']}'),
              direction: workspaceController.userRoleInWorkspace.value == 'viewer' ? DismissDirection.none : DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await _confirmDelete(
                  Get.context!,
                  req['name'] ?? 'Request',
                );
              },
              onDismissed: (direction) {
                parentList.remove(req);
                workspaceController.collections.refresh();
                workspaceController.deleteRequest(req['_id']);
              },
              child: ListTile(
                selected: isSelected,
                selectedTileColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                contentPadding: EdgeInsets.only(
                  left: 40.0 + (depth * 16.0),
                  right: 16.0,
                ),
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (workspaceController.isSelectionMode.value)
                        Checkbox(
                          value: workspaceController.selectedRequestIds
                              .contains(req['_id']),
                          onChanged: (val) {
                            workspaceController.toggleRequestSelection(
                              req['_id'],
                            );
                          },
                        )
                      else
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_indicator,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (savedResponses.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => isExpanded.value = !isExpanded.value,
                          child: Icon(
                            isExpanded.value
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (req['requestKind'] == 'websocket')
                        const Text(
                          'WS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        )
                      else if (req['requestKind'] == 'socketio')
                        const Text(
                          'IO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        )
                      else
                        Text(
                          req['method'] ?? 'GET',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getMethodColor(req['method']),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        req['name'] ?? 'Unnamed Request',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (isSelected && reqBuilder.hasUnsavedChanges.value)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
                onTap: () {
                  if (workspaceController.isSelectionMode.value) {
                    workspaceController.toggleRequestSelection(req['_id']);
                  } else {
                    if (reqBuilder.hasUnsavedChanges.value &&
                        reqBuilder.currentRequestId.value != req['_id']) {
                      Get.defaultDialog(
                        title: 'Unsaved Changes',
                        middleText:
                            'You have unsaved changes. Save before switching?',
                        textConfirm: 'Save',
                        textCancel: 'Discard',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.blue,
                        onConfirm: () async {
                          await reqBuilder.saveChanges();
                          Get.back();
                          reqBuilder.loadRequest(req, path: path);
                        },
                        onCancel: () {
                          reqBuilder.loadRequest(req, path: path);
                        },
                      );
                    } else {
                      reqBuilder.loadRequest(req, path: path);
                    }
                  }
                },
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  hoverColor: Colors.red.withOpacity(0.1),
                  tooltip: 'Delete Request',
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Delete Request',
                      middleText: 'Delete ${req['name']}?',
                      textConfirm: 'Delete',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.red,
                      onConfirm: () {
                        workspaceController.deleteRequest(req['_id']);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            )), // Close Dismissible and Obx
            if (isExpanded.value && savedResponses.isNotEmpty)
              ...savedResponses
                  .map<Widget>(
                    (res) => _buildSavedResponseItem(
                      res,
                      req,
                      savedResponses,
                      depth + 1,
                      path,
                    ),
                  )
                  .toList(),
          ],
        );
      }),
    );
  }

  Widget _buildSavedResponseItem(
    dynamic res,
    dynamic req,
    List<dynamic> parentList,
    int depth,
    String path,
  ) {
    return Dismissible(
      key: ValueKey('res_dismiss_${res['_id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDelete(
          Get.context!,
          res['name'] ?? 'Saved Response',
        );
      },
      onDismissed: (direction) {
        parentList.remove(res);
        workspaceController.collections.refresh();
        workspaceController.deleteSavedResponse(req['_id'], res['_id']);
      },
      child: ListTile(
        contentPadding: EdgeInsets.only(
          left: 40.0 + (depth * 16.0),
          right: 16.0,
        ),
        visualDensity: VisualDensity.compact,
        dense: true,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text(
                'e.g.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${res['status'] ?? 200}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(res['status']),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                res['name'] ?? 'Saved Response',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.more_horiz, size: 14, color: Colors.grey),
        onTap: () {
          if (reqBuilder.hasUnsavedChanges.value &&
              reqBuilder.currentRequestId.value != req['_id']) {
            Get.defaultDialog(
              title: 'Unsaved Changes',
              middleText: 'You have unsaved changes. Save before switching?',
              textConfirm: 'Save',
              textCancel: 'Discard',
              confirmTextColor: Colors.white,
              buttonColor: Colors.blue,
              onConfirm: () async {
                await reqBuilder.saveChanges();
                Get.back();
                reqBuilder.loadSavedResponse(req, res, path: path);
              },
              onCancel: () {
                reqBuilder.loadSavedResponse(req, res, path: path);
              },
            );
          } else {
            reqBuilder.loadSavedResponse(req, res, path: path);
          }
        },
      ),
    );
  }

  void _showVariablesDialog(BuildContext context, dynamic collection) {
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

  Color _getStatusColor(int? status) {
    if (status == null) return AppTheme.textSecondary;
    if (status >= 200 && status < 300) return AppTheme.getMethod;
    if (status >= 400 && status < 500) return AppTheme.postMethod;
    if (status >= 500) return AppTheme.deleteMethod;
    return AppTheme.putMethod;
  }
}
