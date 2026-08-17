import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'dart:convert';
import '../../data/providers/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

class WorkspaceController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final collections = <dynamic>[].obs;
  final isLoading = false.obs;

  final workspaces = <dynamic>[].obs;
  final selectedWorkspaceId = RxnString();
  final userRoleInWorkspace = 'owner'.obs; // 'owner', 'admin', 'editor', 'viewer'


  final sidebarWidth = 300.0.obs;
  final isSidebarVisible = true.obs;

  void toggleSidebar() {
    isSidebarVisible.value = !isSidebarVisible.value;
  }

  void updateSidebarWidth(double delta) {
    double newWidth = sidebarWidth.value + delta;
    if (newWidth > 150 && newWidth < 800) {
      sidebarWidth.value = newWidth;
    }
  }

  final isSelectionMode = false.obs;
  final selectedCollectionIds = <String>{}.obs;
  final selectedRequestIds = <String>{}.obs;

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedCollectionIds.clear();
      selectedRequestIds.clear();
    }
  }

  void toggleCollectionSelection(String id) {
    if (selectedCollectionIds.contains(id)) {
      selectedCollectionIds.remove(id);
    } else {
      selectedCollectionIds.add(id);
    }
  }

  void toggleRequestSelection(String id) {
    if (selectedRequestIds.contains(id)) {
      selectedRequestIds.remove(id);
    } else {
      selectedRequestIds.add(id);
    }
  }

  Future<void> bulkDeleteSelected() async {
    if (selectedCollectionIds.isEmpty && selectedRequestIds.isEmpty) return;
    
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      // Delete requests
      for (final id in selectedRequestIds) {
        await _apiService.deleteRequest(id);
      }
      // Delete collections/folders
      for (final id in selectedCollectionIds) {
        await _apiService.deleteCollection(id);
      }
      
      toggleSelectionMode();
      await fetchCollections();
      Get.back(); // close loader
      Get.snackbar('Success', 'Selected items deleted successfully');
    } catch (e, stack) {
      Get.back(); // close loader
      log('Failed to bulk delete', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to delete some items');
    }
  }

  Future<void> updateCollectionVariables(String id, List<Map<String, dynamic>> variables) async {
    try {
      await _apiService.updateCollection(id, {'variables': variables});
      await fetchCollections();
    } catch (e, stack) {
      log('Failed to update variables', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to save variables');
    }
  }

  Map<String, String> getVariablesForRequest(String requestId) {
    Map<String, String> resolvedVariables = {};
    
    bool findPath(List<dynamic> currentLevel, List<dynamic> path) {
      for (final node in currentLevel) {
        path.add(node);
        
        if (node['requests'] != null) {
          for (final req in node['requests']) {
            if (req['_id'] == requestId) {
              return true;
            }
          }
        }
        
        if (node['folders'] != null && node['folders'].isNotEmpty) {
          if (findPath(node['folders'], path)) {
            return true;
          }
        }
        
        path.removeLast();
      }
      return false;
    }
    
    List<dynamic> pathToRequest = [];
    findPath(collections, pathToRequest);
    
    for (final node in pathToRequest) {
      if (node['variables'] != null) {
        for (final variable in node['variables']) {
          if (variable['enabled'] == true && variable['key'] != null && variable['key'].toString().isNotEmpty) {
            resolvedVariables[variable['key']] = variable['value']?.toString() ?? '';
          }
        }
      }
    }
    
    return resolvedVariables;
  }

  Map<String, VariableDetail> getVariableDetailsForRequest(String requestId) {
    Map<String, VariableDetail> resolvedVariables = {};
    
    bool findPath(List<dynamic> currentLevel, List<dynamic> path) {
      for (final node in currentLevel) {
        path.add(node);
        
        if (node['requests'] != null) {
          for (final req in node['requests']) {
            if (req['_id'] == requestId) {
              return true;
            }
          }
        }
        
        if (node['folders'] != null && node['folders'].isNotEmpty) {
          if (findPath(node['folders'], path)) {
            return true;
          }
        }
        
        path.removeLast();
      }
      return false;
    }
    
    List<dynamic> pathToRequest = [];
    findPath(collections, pathToRequest);
    
    for (final node in pathToRequest) {
      if (node['variables'] != null) {
        final List<dynamic> sourceVariables = node['variables'];
        for (final variable in sourceVariables) {
          if (variable['enabled'] == true && variable['key'] != null && variable['key'].toString().isNotEmpty) {
            final key = variable['key'] as String;
            final value = variable['value']?.toString() ?? '';
            final sourceId = node['_id'] as String;
            final sourceName = node['name'] ?? 'Collection';
            
            resolvedVariables[key] = VariableDetail(key, value, sourceId, sourceName, sourceVariables);
          }
        }
      }
    }
    
    return resolvedVariables;
  }

  Future<void> updateSingleVariable(VariableDetail detail, String newValue) async {
    final variables = detail.sourceVariables;
    bool found = false;
    for (var variable in variables) {
      if (variable['key'] == detail.key) {
        variable['value'] = newValue;
        found = true;
        break;
      }
    }
    
    if (found) {
      List<Map<String, dynamic>> updatedVariables = List<Map<String, dynamic>>.from(variables);
      await updateCollectionVariables(detail.sourceId, updatedVariables);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initWorkspace();
  }

  Future<void> _initWorkspace() async {
    await fetchWorkspaces();
    final prefs = await SharedPreferences.getInstance();
    final savedWs = prefs.getString('selectedWorkspaceId');
    if (savedWs != null && workspaces.any((w) => w['_id'] == savedWs)) {
      switchWorkspace(savedWs);
    } else {
      switchWorkspace(null);
    }
  }

  Future<void> fetchWorkspaces() async {
    try {
      final data = await _apiService.getWorkspaces();
      workspaces.value = data;
    } catch (e, stack) {
      log('Failed to fetch workspaces', error: e, stackTrace: stack, name: 'WorkspaceController');
    }
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);
      return data['id'];
    } catch (e) {
      return null;
    }
  }

  void switchWorkspace(String? workspaceId) async {
    selectedWorkspaceId.value = workspaceId;
    final prefs = await SharedPreferences.getInstance();
    if (workspaceId == null) {
      await prefs.remove('selectedWorkspaceId');
      userRoleInWorkspace.value = 'owner';
    } else {
      await prefs.setString('selectedWorkspaceId', workspaceId);
      userRoleInWorkspace.value = 'viewer';
      try {
        final token = prefs.getString('accessToken');
        if (token != null) {
          final userId = _getUserIdFromToken(token);
          final ws = workspaces.firstWhere((w) => w['_id'] == workspaceId, orElse: () => null);
          if (ws != null && userId != null) {
            if (ws['owner']['_id'] == userId) {
              userRoleInWorkspace.value = 'owner';
            } else {
              final members = ws['members'] as List;
              final member = members.firstWhere((m) => m['user']['_id'] == userId, orElse: () => null);
              if (member != null) {
                userRoleInWorkspace.value = member['role'] ?? 'viewer';
              }
            }
          }
        }
      } catch (e) {
        log('Failed to determine role', error: e, name: 'WorkspaceController');
      }
    }
    fetchCollections();
  }

  Future<void> createWorkspace(String name) async {
    try {
      await _apiService.createWorkspace(name);
      await fetchWorkspaces();
      Get.snackbar('Success', 'Team created successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create team');
    }
  }

  Future<void> deleteWorkspace(String id) async {
    try {
      await _apiService.deleteWorkspace(id);
      if (selectedWorkspaceId.value == id) switchWorkspace(null);
      await fetchWorkspaces();
      Get.snackbar('Success', 'Team deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete team');
    }
  }

  Future<void> addWorkspaceMember(String workspaceId, String email, String role) async {
    try {
      await _apiService.addWorkspaceMember(workspaceId, email, role);
      await fetchWorkspaces();
      Get.snackbar('Success', 'Member invited');
    } catch (e, stack) {
      log('Failed to add member', error: e, stackTrace: stack, name: 'WorkspaceController');
      final msg = e is DioException ? e.response?.data['message'] ?? 'Failed to add member' : 'Failed to add member';
      Get.snackbar('Error', msg);
    }
  }

  Future<void> updateWorkspaceMemberRole(String workspaceId, String userId, String role) async {
    try {
      await _apiService.updateWorkspaceMemberRole(workspaceId, userId, role);
      await fetchWorkspaces();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update role');
    }
  }

  Future<void> removeWorkspaceMember(String workspaceId, String userId) async {
    try {
      await _apiService.removeWorkspaceMember(workspaceId, userId);
      await fetchWorkspaces();
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove member');
    }
  }

  Future<void> transferCollection(String collectionId, String? targetWorkspaceId) async {
    try {
      await _apiService.updateCollection(collectionId, {'workspace': targetWorkspaceId ?? 'null'});
      await fetchCollections();
      Get.snackbar('Success', 'Collection transferred successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to transfer collection');
    }
  }

  Future<void> fetchCollections() async {
    try {
      isLoading.value = true;
      final data = await _apiService.getCollections(workspaceId: selectedWorkspaceId.value);
      collections.value = data;
    } catch (e, stack) {
      log('Failed to fetch collections', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to fetch collections');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> importPostmanCollection(String jsonString) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      await _apiService.importCollection(parsedJson, workspaceId: selectedWorkspaceId.value);
      await fetchCollections(); // Refresh the list
      Get.back(); // close loader
      Get.snackbar('Success', 'Collection imported successfully!');
    } catch (e, stack) {
      Get.back(); // close loader
      log('Failed to import collection', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to import. Invalid JSON or server error.');
    }
  }

  Future<void> createCollection(String name) async {
    try {
      await _apiService.createCollection(name, workspaceId: selectedWorkspaceId.value);
      await fetchCollections(); // Refresh list
    } catch (e, stack) {
      log('Failed to create collection', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to create collection');
    }
  }

  Future<void> createFolder(String parentId, String name) async {
    try {
      await _apiService.createFolder(parentId, name, workspaceId: selectedWorkspaceId.value);
      await fetchCollections(); // Refresh list
    } catch (e, stack) {
      log('Failed to create folder', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to create folder');
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await _apiService.deleteCollection(id);
      await fetchCollections();
      Get.snackbar('Success', 'Deleted successfully');
    } catch (e, stack) {
      log('Failed to delete collection', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to delete');
    }
  }

  Future<void> reorderRequests(List<dynamic> requestList, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Optimistic UI update
    final item = requestList.removeAt(oldIndex);
    requestList.insert(newIndex, item);
    collections.refresh(); // trigger Obx update

    try {
      final requestIds = requestList.map<String>((r) => r['_id'] as String).toList();
      await _apiService.reorderRequests(requestIds);
    } catch (e, stack) {
      log('Failed to reorder requests', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to save new order');
      await fetchCollections(); // revert on failure
    }
  }

  Future<void> createRequest(String collectionId, String name, String method, String requestKind) async {
    try {
      await _apiService.createRequest(collectionId, name, method, requestKind: requestKind);
      await fetchCollections(); // Refresh list to show new nested request
    } catch (e, stack) {
      log('Failed to create request', error: e, stackTrace: stack, name: 'WorkspaceController');
      String msg = 'Failed to create request';
      if (e is DioException && e.response != null) {
        msg = e.response?.data['message'] ?? msg;
        log('DioResponse: ${e.response?.data}', name: 'WorkspaceController');
      }
      Get.snackbar('Error', msg);
    }
  }

  Future<void> deleteRequest(String id) async {
    try {
      await _apiService.deleteRequest(id);
      await fetchCollections();
      Get.snackbar('Success', 'Request deleted');
    } catch (e, stack) {
      log('Failed to delete request', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to delete request');
    }
  }

  Future<void> deleteSavedResponse(String requestId, String responseId) async {
    try {
      await _apiService.deleteSavedResponse(requestId, responseId);
      await fetchCollections();
      Get.snackbar('Success', 'Response deleted');
    } catch (e, stack) {
      log('Failed to delete response', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to delete response');
    }
  }

  // Future<void> bulkDeleteSelected() async {
  //   bool hasError = false;
    
  //   // Delete requests
  //   for (final id in selectedRequestIds) {
  //     try {
  //       await _apiService.deleteRequest(id);
  //     } catch (e) {
  //       hasError = true;
  //     }
  //   }
    
  //   // Delete collections
  //   for (final id in selectedCollectionIds) {
  //     try {
  //       await _apiService.deleteCollection(id);
  //     } catch (e) {
  //       hasError = true;
  //     }
  //   }
    
  //   if (hasError) {
  //     Get.snackbar('Warning', 'Some items failed to delete');
  //   } else {
  //     Get.snackbar('Success', 'Selected items deleted');
  //   }
    
  //   toggleSelectionMode();
  //   await fetchCollections();
  // }
}

class VariableDetail {
  final String key;
  final String value;
  final String sourceId;
  final String sourceName;
  final List<dynamic> sourceVariables;

  VariableDetail(this.key, this.value, this.sourceId, this.sourceName, this.sourceVariables);
}
