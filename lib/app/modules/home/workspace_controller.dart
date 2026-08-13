import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'dart:convert';
import '../../data/providers/api_service.dart';

import 'package:flutter/material.dart';

class WorkspaceController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final collections = <dynamic>[].obs;
  final isLoading = false.obs;

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

  @override
  void onInit() {
    super.onInit();
    fetchCollections();
  }

  Future<void> fetchCollections() async {
    try {
      isLoading.value = true;
      final data = await _apiService.getCollections();
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
      await _apiService.importCollection(parsedJson);
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
      await _apiService.createCollection(name);
      await fetchCollections(); // Refresh list
    } catch (e, stack) {
      log('Failed to create collection', error: e, stackTrace: stack, name: 'WorkspaceController');
      Get.snackbar('Error', 'Failed to create collection');
    }
  }

  Future<void> createFolder(String parentId, String name) async {
    try {
      await _apiService.createFolder(parentId, name);
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

  Future<void> createRequest(String collectionId, String name, String method) async {
    try {
      await _apiService.createRequest(collectionId, name, method);
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
