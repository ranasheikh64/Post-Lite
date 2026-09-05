import 'network_caller.dart';

class ApiService {
  final NetworkCaller _network = NetworkCaller();

  // --- Workspaces ---

  Future<List<dynamic>> getWorkspaces() async {
    final response = await _network.getRequest('/workspaces');
    return response.data;
  }

  Future<Map<String, dynamic>> createWorkspace(String name) async {
    final response = await _network.postRequest('/workspaces', data: {'name': name});
    return response.data;
  }

  Future<void> deleteWorkspace(String id) async {
    await _network.deleteRequest('/workspaces/$id');
  }

  Future<Map<String, dynamic>> addWorkspaceMember(String workspaceId, String email, String role) async {
    final response = await _network.postRequest('/workspaces/$workspaceId/members', data: {'email': email, 'role': role});
    return response.data;
  }

  Future<Map<String, dynamic>> updateWorkspaceMemberRole(String workspaceId, String userId, String role) async {
    final response = await _network.patchRequest('/workspaces/$workspaceId/members/$userId', data: {'role': role});
    return response.data;
  }

  Future<void> removeWorkspaceMember(String workspaceId, String userId) async {
    await _network.deleteRequest('/workspaces/$workspaceId/members/$userId');
  }

  // --- Collections ---
  
  Future<List<dynamic>> getCollections({String? workspaceId}) async {
    final response = await _network.getRequest('/collections', queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
    });
    return response.data;
  }

  Future<void> importCollection(Map<String, dynamic> json, {String? workspaceId}) async {
    await _network.postRequest('/collections/import', data: json, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
    });
  }

  Future<Map<String, dynamic>> createCollection(String name, {String? workspaceId}) async {
    final response = await _network.postRequest('/collections', data: {
      'name': name,
      if (workspaceId != null) 'workspace': workspaceId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateCollection(String id, Map<String, dynamic> data) async {
    final response = await _network.patchRequest('/collections/$id', data: data);
    return response.data;
  }

  Future<void> deleteCollection(String id) async {
    await _network.deleteRequest('/collections/$id');
  }

  // --- Folders ---

  Future<Map<String, dynamic>> createFolder(String collectionId, String name, {String? parentId}) async {
    final response = await _network.postRequest('/folders', data: {
      'collection': collectionId,
      'name': name,
      if (parentId != null) 'parent': parentId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateFolder(String id, Map<String, dynamic> data) async {
    final response = await _network.patchRequest('/folders/$id', data: data);
    return response.data;
  }

  Future<void> deleteFolder(String id) async {
    await _network.deleteRequest('/folders/$id');
  }

  // --- Requests ---

  Future<Map<String, dynamic>> createRequest(String collectionId, String name, {String? folderId, String method = 'GET', String requestKind = 'HTTP'}) async {
    final response = await _network.postRequest('/requests', data: {
      'collection': collectionId,
      'name': name,
      'method': method,
      'requestKind': requestKind,
      'url': '',
      if (folderId != null) 'folder': folderId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateRequest(String id, Map<String, dynamic> data) async {
    final response = await _network.patchRequest('/requests/$id', data: data);
    return response.data;
  }

  Future<void> deleteRequest(String id) async {
    await _network.deleteRequest('/requests/$id');
  }

  Future<void> reorderRequests(List<String> requestIds) async {
    await _network.patchRequest('/requests/reorder', data: {'requestIds': requestIds});
  }

  Future<Map<String, dynamic>> saveResponse(String requestId, Map<String, dynamic> responseData) async {
    final response = await _network.postRequest('/requests/$requestId/responses', data: responseData);
    return response.data;
  }

  Future<void> deleteSavedResponse(String requestId, String responseId) async {
    await _network.deleteRequest('/requests/$requestId/responses/$responseId');
  }
}
