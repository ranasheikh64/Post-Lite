import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/request_builder_controller.dart';
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

  void _showBulkDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${workspaceController.selectedCollectionIds.length + workspaceController.selectedRequestIds.length} selected items?\n\nDeleting folders will also delete all their nested folders and requests.'),
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
                  if (defaultCollectionId == null && workspaceController.collections.isNotEmpty)
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
                  if (defaultCollectionId == null && workspaceController.collections.isEmpty)
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
                                            color: m == 'GET'
                                                ? Colors.green
                                                : m == 'POST'
                                                ? Colors.orange
                                                : m == 'DELETE'
                                                ? Colors.red
                                                : m == 'PUT'
                                                ? Colors.blue
                                                : m == 'PATCH'
                                                ? Colors.purple
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => selectedMethod = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
          Container(
            width: 300,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Text(
                        workspaceController.isSelectionMode.value 
                            ? '${workspaceController.selectedCollectionIds.length + workspaceController.selectedRequestIds.length} selected'
                            : 'Collections',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                      Obx(() => Row(
                        children: [
                          if (workspaceController.isSelectionMode.value) ...[
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              tooltip: 'Delete Selected',
                              onPressed: () {
                                if (workspaceController.selectedCollectionIds.isNotEmpty || 
                                    workspaceController.selectedRequestIds.isNotEmpty) {
                                  _showBulkDeleteDialog(context);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              tooltip: 'Cancel Selection',
                              onPressed: workspaceController.toggleSelectionMode,
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.checklist, size: 20),
                              tooltip: 'Select multiple',
                              onPressed: workspaceController.toggleSelectionMode,
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
                                      Icon(Icons.folder, size: 18),
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
                                      Icon(Icons.file_upload, size: 18),
                                      SizedBox(width: 8),
                                      Text('Import JSON'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      )),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Obx(() {
                    if (workspaceController.isLoading.value &&
                        workspaceController.collections.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (workspaceController.collections.isEmpty) {
                      return const Center(child: Text('No collections yet.'));
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
          const VerticalDivider(width: 1),
          // Main Area
          const Expanded(child: RequestBuilderView()),
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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

    return Dismissible(
      key: ValueKey('collection_${collection['_id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDelete(context, collection['name'] ?? 'Collection');
      },
      onDismissed: (direction) {
        parentList.remove(collection);
        workspaceController.collections.refresh();
        workspaceController.deleteCollection(collection['_id']);
      },
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16.0),
        leading: Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (workspaceController.isSelectionMode.value)
              Checkbox(
                value: workspaceController.selectedCollectionIds.contains(collection['_id']),
                onChanged: (val) {
                  workspaceController.toggleCollectionSelection(collection['_id']);
                },
              ),
            Icon(
              depth == 0 ? Icons.folder : Icons.folder_open,
              color: depth == 0 ? Colors.amber : Colors.amber.shade300,
            ),
          ],
        )),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                collection['name'] ?? 'Unnamed',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Add Folder',
                onPressed: () {
                  _showAddFolderDialog(context, collection['_id']);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Add Request',
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
                  Icons.delete,
                  size: 18,
                  color: Colors.redAccent,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete',
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Delete',
                    middleText:
                        'Are you sure you want to delete ${collection['name']} and all its contents?',
                    textConfirm: 'Delete',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      workspaceController.deleteCollection(collection['_id']);
                      Get.back();
                    },
                  );
                },
              ),
            ],
          ),
        ],
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
              workspaceController.reorderRequests(requests, oldIndex, newIndex);
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
    );
  }

  Widget _buildRequestItem(dynamic req, List<dynamic> parentList, int depth, Key key, String path, int index) {
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
            Dismissible(
              key: ValueKey('req_dismiss_${req['_id']}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await _confirmDelete(Get.context!, req['name'] ?? 'Request');
              },
              onDismissed: (direction) {
                parentList.remove(req);
                workspaceController.collections.refresh();
                workspaceController.deleteRequest(req['_id']);
              },
              child: ListTile(
                selected: isSelected,
                selectedTileColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                contentPadding: EdgeInsets.only(
                  left: 40.0 + (depth * 16.0),
                  right: 16.0,
                ),
                title: Row(
                children: [
                  if (workspaceController.isSelectionMode.value)
                    Checkbox(
                      value: workspaceController.selectedRequestIds.contains(req['_id']),
                      onChanged: (val) {
                        workspaceController.toggleRequestSelection(req['_id']);
                      },
                    )
                  else
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  if (savedResponses.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => isExpanded.value = !isExpanded.value,
                      child: Icon(
                        isExpanded.value ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    req['method'] ?? 'GET',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: req['method'] == 'GET'
                          ? Colors.green
                          : req['method'] == 'POST'
                          ? Colors.orange
                          : req['method'] == 'DELETE'
                          ? Colors.red
                          : req['method'] == 'PUT'
                          ? Colors.blue
                          : req['method'] == 'PATCH'
                          ? Colors.purple
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req['name'] ?? 'Unnamed Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected && reqBuilder.hasUnsavedChanges.value)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.circle, size: 8, color: Colors.orange),
                    ),
                ],
              ),
              onTap: () {
                if (workspaceController.isSelectionMode.value) {
                  workspaceController.toggleRequestSelection(req['_id']);
                } else {
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
                icon: const Icon(Icons.delete, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
            ), // Close Dismissible
            if (isExpanded.value && savedResponses.isNotEmpty)
              ...savedResponses.map<Widget>((res) => _buildSavedResponseItem(res, req, savedResponses, depth + 1, path)).toList(),
          ],
        );
      }),
    );
  }

  Widget _buildSavedResponseItem(dynamic res, dynamic req, List<dynamic> parentList, int depth, String path) {
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
        return await _confirmDelete(Get.context!, res['name'] ?? 'Saved Response');
      },
      onDismissed: (direction) {
        parentList.remove(res);
        workspaceController.collections.refresh();
        workspaceController.deleteSavedResponse(req['_id'], res['_id']);
      },
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 40.0 + (depth * 16.0), right: 16.0),
        visualDensity: VisualDensity.compact,
        dense: true,
        title: Row(
          children: [
            const Icon(Icons.description_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('e.g.', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(width: 4),
            Text('${res['status'] ?? 200}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(res['status']))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                res['name'] ?? 'Saved Response', 
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    if (status == null) return Colors.grey;
    if (status >= 200 && status < 300) return Colors.green;
    if (status >= 400 && status < 500) return Colors.orange;
    if (status >= 500) return Colors.red;
    return Colors.blue;
  }
}
