import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:4000'));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refreshToken');
          
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:4000/auth'));
              final refreshResponse = await refreshDio.post('/refresh', data: {
                'refreshToken': refreshToken,
              });
              
              if (refreshResponse.statusCode == 200) {
                final newAccessToken = refreshResponse.data['accessToken'];
                await prefs.setString('accessToken', newAccessToken);
                
                // Retry the original request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await Dio().fetch(opts);
                return handler.resolve(cloneReq);
              }
            } catch (e) {
              // Refresh failed, clear tokens (user must log in again)
              await prefs.remove('accessToken');
              await prefs.remove('refreshToken');
            }
          }
        }
        return handler.next(error);
      },
    ));
  }
  // --- Workspaces ---

  Future<List<dynamic>> getWorkspaces() async {
    final response = await _dio.get('/workspaces');
    return response.data;
  }

  Future<Map<String, dynamic>> createWorkspace(String name) async {
    final response = await _dio.post('/workspaces', data: {'name': name});
    return response.data;
  }

  Future<void> deleteWorkspace(String id) async {
    await _dio.delete('/workspaces/$id');
  }

  Future<Map<String, dynamic>> addWorkspaceMember(String workspaceId, String email, String role) async {
    final response = await _dio.post('/workspaces/$workspaceId/members', data: {'email': email, 'role': role});
    return response.data;
  }

  Future<Map<String, dynamic>> updateWorkspaceMemberRole(String workspaceId, String userId, String role) async {
    final response = await _dio.patch('/workspaces/$workspaceId/members/$userId', data: {'role': role});
    return response.data;
  }

  Future<void> removeWorkspaceMember(String workspaceId, String userId) async {
    await _dio.delete('/workspaces/$workspaceId/members/$userId');
  }
  // --- Collections ---
  
  Future<List<dynamic>> getCollections({String? workspaceId}) async {
    final response = await _dio.get('/collections', queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
    });
    return response.data;
  }

  Future<void> importCollection(Map<String, dynamic> json, {String? workspaceId}) async {
    await _dio.post('/collections/import', data: json, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
    });
  }

  Future<Map<String, dynamic>> createCollection(String name, {String? workspaceId}) async {
    final response = await _dio.post('/collections', data: {
      'name': name,
      if (workspaceId != null) 'workspace': workspaceId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateCollection(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/collections/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> createFolder(String parentId, String name, {String? workspaceId}) async {
    final response = await _dio.post('/collections', data: {
      'name': name, 
      'parentFolder': parentId,
      if (workspaceId != null) 'workspace': workspaceId,
    });
    return response.data;
  }

  Future<void> deleteCollection(String id) async {
    await _dio.delete('/collections/$id');
  }

  // --- Requests ---

  Future<Map<String, dynamic>> createRequest(String collectionId, String name, String method, {String requestKind = 'http'}) async {
    final response = await _dio.post('/requests', data: {
      'collectionId': collectionId,
      'name': name,
      'method': method,
      'requestKind': requestKind,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateRequest(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/requests/$id', data: data);
    return response.data;
  }

  Future<void> deleteRequest(String id) async {
    await _dio.delete('/requests/$id');
  }

  Future<void> reorderRequests(List<String> requestIds) async {
    await _dio.patch('/requests/reorder', data: {'requestIds': requestIds});
  }

  Future<Map<String, dynamic>> saveResponse(String requestId, Map<String, dynamic> responseData) async {
    final response = await _dio.post('/requests/$requestId/responses', data: responseData);
    return response.data;
  }

  Future<void> deleteSavedResponse(String requestId, String responseId) async {
    await _dio.delete('/requests/$requestId/responses/$responseId');
  }
}
