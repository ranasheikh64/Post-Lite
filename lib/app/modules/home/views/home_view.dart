import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import '../../request_builder/views/request_builder_view.dart';
import '../controllers/workspace_controller.dart';
import 'package:postmanclone/app/core/utils/dialog_helper.dart';
import '../widgets/dialogs/add_collection_dialog.dart';
import '../widgets/dialogs/import_dialog.dart';
import '../widgets/dialogs/add_folder_dialog.dart';
import '../widgets/dialogs/transfer_dialog.dart';
import '../widgets/dialogs/bulk_delete_dialog.dart';
import '../widgets/dialogs/variables_dialog.dart';
import '../widgets/dialogs/add_request_dialog.dart';
import '../widgets/dialogs/rename_request_dialog.dart';
import '../widgets/global_search_widget.dart';
import '../widgets/top_bar_sync_button.dart';
import '../widgets/sidebar_shimmer_loader.dart';
import '../widgets/sidebar_workspace_selector.dart';

class HomeView extends GetView<WorkspaceController> {
  HomeView({super.key});

  WorkspaceController get workspaceController => controller;
  final RequestBuilderController reqBuilder = Get.put(
    RequestBuilderController(),
  );

  @override
  Widget build(BuildContext context) {
    final reqBuilder = Get.find<RequestBuilderController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (reqBuilder.hasAnyUnsavedChanges()) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF222533),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Unsaved Changes', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: const Text(
                'You have unsaved changes in your open tabs. Are you sure you want to close and lose them?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                  child: const Text('Discard & Exit', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        } else {
          SystemNavigator.pop();
        }
      },
      child: DropTarget(
        onDragDone: (detail) async {
          for (final file in detail.files) {
            if (file.name.toLowerCase().endsWith('.json')) {
              try {
                final content = await file.readAsString();
                await workspaceController.importPostmanCollection(content);
              } catch (e) {
                debugPrint('Failed to read dropped file: $e');
              }
            }
          }
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1C27),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2A2D3E), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Sidebar toggle
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: workspaceController.toggleSidebar,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Icon(
                        Icons.menu_rounded,
                        size: 20,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),
                // Logo + App name
                Image.asset('assets/icons/main_logo.png', height: 28),
                const SizedBox(width: 8),
                const Text(
                  'Jronix Post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(width: 24),
                // Global Search Box
                const Expanded(
                  child: Center(
                    child: SizedBox(width: 420, child: GlobalSearchWidget()),
                  ),
                ),
                const SizedBox(width: 24),
                // Actions
                const TopBarSyncButton(),
                Tooltip(
                  message: 'Settings',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.toNamed(Routes.SETTINGS),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        child: Icon(Icons.settings_outlined, size: 18, color: Color(0xFF9E9E9E)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
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
                    child: Material(
                      color: const Color(0xFF181A25),
                      child: Column(
                        children: [
                          // Workspace Switcher
                          SidebarWorkspaceSelector(
                            workspaceController: workspaceController,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF9E9E9E),
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
                                              showBulkDeleteDialog(
                                                context,
                                                workspaceController,
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                          ),
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
                                              showAddCollectionDialog(
                                                context,
                                                workspaceController,
                                              );
                                            } else if (value ==
                                                'request_http') {
                                              showAddRequestDialog(
                                                context,
                                                workspaceController:
                                                    workspaceController,
                                                defaultKind: 'http',
                                              );
                                            } else if (value == 'request_ws') {
                                              showAddRequestDialog(
                                                context,
                                                workspaceController:
                                                    workspaceController,
                                                defaultKind: 'websocket',
                                              );
                                            } else if (value == 'request_io') {
                                              showAddRequestDialog(
                                                context,
                                                workspaceController:
                                                    workspaceController,
                                                defaultKind: 'socketio',
                                              );
                                            } else if (value == 'import') {
                                              showImportDialog(
                                                context,
                                                workspaceController,
                                              );
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
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'request_http',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.http,
                                                    size: 18,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('New HTTP Request'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'request_ws',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.swap_calls,
                                                    size: 18,
                                                    color: Colors.purple,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('New WebSocket Request'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'request_io',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.sensors,
                                                    size: 18,
                                                    color: Colors.orange,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('New Socket.IO Request'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
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
                              if (workspaceController.isLoading.value) {
                                return const SidebarShimmerLoader();
                              }
                              if (workspaceController.collections.isEmpty) {
                                return const Center(
                                  child: Text('No collections yet.'),
                                );
                              }
                              return ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                itemCount: workspaceController.collections.length,
                                proxyDecorator: (child, index, animation) => Material(
                                  color: const Color(0xFF1E2133),
                                  borderRadius: BorderRadius.circular(4),
                                  elevation: 6,
                                  child: child,
                                ),
                                onReorder: (oldIndex, newIndex) {
                                  workspaceController.reorderFolders(
                                    workspaceController.collections,
                                    oldIndex,
                                    newIndex,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  return _buildRootCollectionItem(
                                    context,
                                    workspaceController.collections[index],
                                    workspaceController.collections,
                                    index,
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
      ),
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

  Widget _buildRootCollectionItem(
    BuildContext context,
    dynamic collection,
    List<dynamic> parentList,
    int index,
  ) {
    final collectionId = collection['_id'];
    return Container(
      key: ValueKey('root_col_$collectionId'),
      child: Obx(() {
        final isExpanded = workspaceController.isCollectionExpanded(collectionId);
        final folders = (collection['folders'] as List?) ?? [];
        final requests = (collection['requests'] as List?) ?? [];
        final currentPath = 'Workspace > ${collection['name']}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCollectionHeaderTile(
              context,
              collection,
              parentList,
              isExpanded,
              false,
              index: index,
            ),
            if (isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Render sub-folders
                  if (folders.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: folders.length,
                      proxyDecorator: (child, index, animation) => Material(
                        color: const Color(0xFF1E2133),
                        borderRadius: BorderRadius.circular(4),
                        child: child,
                      ),
                      onReorder: (oldIndex, newIndex) {
                        workspaceController.reorderFolders(
                          folders,
                          oldIndex,
                          newIndex,
                        );
                      },
                      itemBuilder: (context, idx) {
                        final f = folders[idx];
                        return _buildCollectionNode(
                          context,
                          f,
                          folders,
                          1,
                          parentPath: currentPath,
                          index: idx,
                        );
                      },
                    ),
                  // Render requests with ReorderableListView
                  if (requests.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      proxyDecorator: (child, index, animation) => Material(
                        color: const Color(0xFF1E2133),
                        borderRadius: BorderRadius.circular(4),
                        child: child,
                      ),
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
                          0,
                          ValueKey(req['_id']),
                          currentPath,
                          idx,
                        );
                      },
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }

  Widget _buildCollectionHeaderTile(
    BuildContext context,
    dynamic collection,
    List<dynamic> parentList,
    bool isExpanded,
    bool isPinned, {
    int? index,
  }) {
    final requests = collection['requests'] ?? [];
    final collectionId = collection['_id'];

    return Dismissible(
      key: ValueKey('collection_root_${collection['_id']}'),
      direction: workspaceController.userRoleInWorkspace.value == 'viewer'
          ? DismissDirection.none
          : DismissDirection.endToStart,
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
      child: Material(
        color: isPinned ? const Color(0xFF1C1F2E) : const Color(0xFF151722),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isPinned ? const Color(0xFF1C1F2E) : const Color(0xFF151722),
            border: Border(
              bottom: BorderSide(
                color: isPinned ? const Color(0xFF2A2D3E) : Colors.white10,
                width: isPinned ? 1.0 : 0.5,
              ),
              left: BorderSide(
                color: isPinned ? const Color(0xFFFF6C37) : Colors.transparent,
                width: isPinned ? 2.0 : 0,
              ),
            ),
            boxShadow: isPinned
                ? const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: () {
              workspaceController.toggleCollectionExpanded(collectionId);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Obx(() {
                    if (!workspaceController.isSelectionMode.value) {
                      return const SizedBox.shrink();
                    }
                    return Checkbox(
                      value: workspaceController.selectedCollectionIds.contains(
                        collectionId,
                      ),
                      onChanged: (val) {
                        workspaceController.toggleCollectionSelection(
                          collectionId,
                        );
                      },
                    );
                  }),
                  if (index != null &&
                      !workspaceController.isSelectionMode.value &&
                      workspaceController.userRoleInWorkspace.value != 'viewer') ...[
                    ReorderableDragStartListener(
                      index: index,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Icon(
                          Icons.drag_indicator,
                          size: 14,
                          color: Color(0xFF555870),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded
                        ? Icons.folder_open_outlined
                        : Icons.folder_outlined,
                    color: isExpanded
                        ? const Color(0xFFFF6C37)
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            collection['name'] ?? 'Unnamed',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isExpanded
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isExpanded ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                        if (requests.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${requests.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Obx(() {
                    if (workspaceController.userRoleInWorkspace.value ==
                        'viewer') {
                      return const SizedBox.shrink();
                    }
                    return _buildCollectionPopupMenu(
                      context,
                      collection,
                      depth: 0,
                    );
                  }),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded
                        ? const Color(0xFFFF6C37)
                        : Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionPopupMenu(
    BuildContext context,
    dynamic collection, {
    required int depth,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppTheme.textSecondary,
      ),
      padding: EdgeInsets.zero,
      splashRadius: 20,
      tooltip: 'Options',
      color: const Color(0xFF2A2D3E),
      onSelected: (value) {
        if (value == 'add_folder') {
          showAddFolderDialog(
            context,
            collection['_id'],
            workspaceController,
          );
        } else if (value == 'add_request_http') {
          showAddRequestDialog(
            context,
            defaultCollectionId: collection['_id'],
            workspaceController: workspaceController,
            defaultKind: 'http',
          );
        } else if (value == 'add_request_ws') {
          showAddRequestDialog(
            context,
            defaultCollectionId: collection['_id'],
            workspaceController: workspaceController,
            defaultKind: 'websocket',
          );
        } else if (value == 'add_request_io') {
          showAddRequestDialog(
            context,
            defaultCollectionId: collection['_id'],
            workspaceController: workspaceController,
            defaultKind: 'socketio',
          );
        } else if (value == 'variables') {
          showVariablesDialog(
            context,
            collection,
            workspaceController,
          );
        } else if (value == 'transfer') {
          showTransferDialog(
            context,
            collection,
            workspaceController,
          );
        } else if (value == 'export') {
          workspaceController.exportCollection(collection);
        } else if (value == 'delete') {
          DialogHelper.showConfirmationDialog(
            title: 'Delete Collection',
            message:
                'Are you sure you want to delete ${collection['name']}? This action cannot be undone.',
            confirmText: 'Delete',
            isDestructive: true,
            onConfirm: () {
              workspaceController.deleteCollection(
                collection['_id'],
              );
            },
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add_request_http',
          child: Row(
            children: [
              Icon(
                Icons.http,
                size: 16,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                'Add HTTP Request',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_request_ws',
          child: Row(
            children: [
              Icon(
                Icons.swap_calls,
                size: 16,
                color: Colors.purple,
              ),
              SizedBox(width: 8),
              Text(
                'Add WebSocket Request',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_request_io',
          child: Row(
            children: [
              Icon(
                Icons.sensors,
                size: 16,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                'Add Socket.IO Request',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'add_folder',
          child: Row(
            children: [
              Icon(
                Icons.create_new_folder_outlined,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Add Folder',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        if (depth == 0) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'variables',
            child: Row(
              children: [
                Icon(Icons.tune, size: 16),
                SizedBox(width: 8),
                Text(
                  'Variables',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'transfer',
            child: Row(
              children: [
                Icon(
                  Icons.drive_file_move_outline,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Transfer to Team',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Export Collection',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionNode(
    BuildContext context,
    dynamic collection,
    List<dynamic> parentList,
    int depth, {
    String parentPath = 'Workspace',
    int? index,
  }) {
    final requests = collection['requests'] ?? [];
    final folders = collection['folders'] ?? [];
    final currentPath = '$parentPath > ${collection['name']}';

    return Container(
      key: ValueKey('folder_${collection['_id']}'),
      child: Obx(
        () => Dismissible(
          key: ValueKey('collection_dismiss_${collection['_id']}'),
          direction: workspaceController.userRoleInWorkspace.value == 'viewer'
              ? DismissDirection.none
              : DismissDirection.endToStart,
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
            tilePadding: EdgeInsets.only(
              left: 16.0 + (depth * 16.0),
              right: 16.0,
            ),
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
                    )
                  else if (index != null &&
                      workspaceController.userRoleInWorkspace.value != 'viewer')
                    ReorderableDragStartListener(
                      index: index,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Icon(
                          Icons.drag_indicator,
                          size: 14,
                          color: Color(0xFF555870),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    depth == 0
                        ? Icons.folder_outlined
                        : Icons.folder_open_outlined,
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
                  if (requests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Obx(
                    () =>
                        workspaceController.userRoleInWorkspace.value == 'viewer'
                        ? const SizedBox.shrink()
                        : _buildCollectionPopupMenu(
                            context,
                            collection,
                            depth: depth,
                          ),
                  ),
                ],
              ),
            ),
            children: [
              // Render sub-folders
              if (folders.isNotEmpty)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: folders.length,
                  proxyDecorator: (child, index, animation) => Material(
                    color: const Color(0xFF1E2133),
                    borderRadius: BorderRadius.circular(4),
                    child: child,
                  ),
                  onReorder: (oldIndex, newIndex) {
                    workspaceController.reorderFolders(
                      folders,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, idx) {
                    final f = folders[idx];
                    return _buildCollectionNode(
                      context,
                      f,
                      folders,
                      depth + 1,
                      parentPath: currentPath,
                      index: idx,
                    );
                  },
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
        ),
      ),
    );
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
            Obx(
              () => Dismissible(
                key: ValueKey('req_dismiss_${req['_id']}'),
                direction:
                    workspaceController.userRoleInWorkspace.value == 'viewer'
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
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
                child: Material(
                  color: isSelected
                      ? const Color(0xFF1E2133)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (workspaceController.isSelectionMode.value) {
                        workspaceController.toggleRequestSelection(req['_id']);
                      } else {
                        reqBuilder.loadRequest(
                          Map<String, dynamic>.from(req),
                          path: path,
                        );
                      }
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFF6C37)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left: 32.0 + (depth * 16.0),
                        right: 8.0,
                      ),
                      child: Row(
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
                                size: 14,
                                color: Color(0xFF555870),
                              ),
                            ),
                          const SizedBox(width: 6),
                          if (savedResponses.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () =>
                                  isExpanded.value = !isExpanded.value,
                              child: Icon(
                                isExpanded.value
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_right,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                          // Method badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getMethodBadgeColor(
                                req['requestKind'],
                                req['method'],
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _getMethodLabel(
                                req['requestKind'],
                                req['method'],
                              ),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _getMethodBadgeColor(
                                  req['requestKind'],
                                  req['method'],
                                ),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req['name'] ?? 'Unnamed Request',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFE8E8E8)
                                    : const Color(0xFFAAAAAA),
                              ),
                            ),
                          ),
                          if (isSelected && reqBuilder.hasUnsavedChanges.value)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.orange,
                              ),
                            ),
                          // More options
                          Obx(() {
                            if (workspaceController.duplicatingRequestId.value ==
                                req['_id']) {
                              return const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              );
                            }
                            return workspaceController
                                        .userRoleInWorkspace.value ==
                                    'viewer'
                                ? const SizedBox.shrink()
                                : PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 14,
                                      color: Color(0xFF666980),
                                    ),
                                    padding: EdgeInsets.zero,
                                    splashRadius: 14,
                                    tooltip: 'Options',
                                    color: const Color(0xFF2A2D3E),
                                    onSelected: (value) {
                                      if (value == 'rename') {
                                        showRenameRequestDialog(
                                          Get.context!,
                                          req,
                                          workspaceController,
                                        );
                                      } else if (value == 'duplicate') {
                                        workspaceController.duplicateRequest(
                                          Map<String, dynamic>.from(req),
                                        );
                                      } else if (value == 'delete') {
                                        DialogHelper.showConfirmationDialog(
                                          title: 'Delete Request',
                                          message: 'Are you sure you want to delete ${req['name']}? This action cannot be undone.',
                                          confirmText: 'Delete',
                                          isDestructive: true,
                                          onConfirm: () {
                                            workspaceController.deleteRequest(
                                              req['_id'],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Rename',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'duplicate',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.copy_outlined,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Duplicate',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 14,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ), // Close Dismissible and Obx
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
          reqBuilder.loadSavedResponse(req, res, path: path);
        },
      ),
    );
  }

  Color _getMethodBadgeColor(String? requestKind, String? method) {
    if (requestKind == 'websocket') return Colors.purple;
    if (requestKind == 'socketio') return Colors.orange;
    return AppTheme.getMethodColor(method);
  }

  String _getMethodLabel(String? requestKind, String? method) {
    if (requestKind == 'websocket') return 'WS';
    if (requestKind == 'socketio') return 'IO';
    return method ?? 'GET';
  }

  Color _getStatusColor(int? status) {
    if (status == null) return AppTheme.textSecondary;
    if (status >= 200 && status < 300) return AppTheme.getMethod;
    if (status >= 400 && status < 500) return AppTheme.postMethod;
    if (status >= 500) return AppTheme.deleteMethod;
    return AppTheme.putMethod;
  }
}
