import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import '../../request_builder/views/request_builder_view.dart';
import '../controllers/workspace_controller.dart';
import '../widgets/dialogs/add_collection_dialog.dart';
import '../widgets/dialogs/import_dialog.dart';
import '../widgets/dialogs/add_folder_dialog.dart';
import '../widgets/dialogs/create_team_dialog.dart';
import '../widgets/dialogs/transfer_dialog.dart';
import '../widgets/dialogs/team_settings_dialog.dart';
import '../widgets/dialogs/bulk_delete_dialog.dart';
import '../widgets/dialogs/variables_dialog.dart';
import '../widgets/dialogs/add_request_dialog.dart';

class HomeView extends GetView<WorkspaceController> {
  HomeView({super.key});

  WorkspaceController get workspaceController => controller;
  final RequestBuilderController reqBuilder = Get.put(
    RequestBuilderController(),
  );

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
                                  onPressed: () => showTeamSettingsDialog(context, workspaceController),
                                )
                              else if (workspaceController.selectedWorkspaceId.value == null)
                                IconButton(
                                  icon: const Icon(Icons.group_add, size: 18),
                                  tooltip: 'Create Team',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => showCreateTeamDialog(context, workspaceController),
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
                                            showBulkDeleteDialog(context, workspaceController);
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
                                            showAddCollectionDialog(context, workspaceController);
                                          } else if (value == 'request') {
                                            showAddRequestDialog(context, workspaceController: workspaceController);
                                          } else if (value == 'import') {
                                            showImportDialog(context, workspaceController);
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
                      showAddFolderDialog(context, collection['_id'], workspaceController);
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
                      showAddRequestDialog(
                        context,
                        defaultCollectionId: collection['_id'],
                        workspaceController: workspaceController,
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
                      showVariablesDialog(context, collection, workspaceController);
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
                        showTransferDialog(context, collection, workspaceController);
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
                          reqBuilder.loadRequest(Map<String, dynamic>.from(req), path: path);
                        },
                        onCancel: () {
                          reqBuilder.loadRequest(Map<String, dynamic>.from(req), path: path);
                        },
                      );
                    } else {
                      reqBuilder.loadRequest(Map<String, dynamic>.from(req), path: path);
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

  

  Color _getStatusColor(int? status) {
    if (status == null) return AppTheme.textSecondary;
    if (status >= 200 && status < 300) return AppTheme.getMethod;
    if (status >= 400 && status < 500) return AppTheme.postMethod;
    if (status >= 500) return AppTheme.deleteMethod;
    return AppTheme.putMethod;
  }
}
