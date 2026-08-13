import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';
import 'dart:convert';
import '../../data/providers/api_service.dart';
import '../home/workspace_controller.dart';

class RequestBuilderController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var currentRequestId = RxnString();
  var currentPath = 'Workspace > Collection'.obs;
  
  // -- Request State --
  var method = 'GET'.obs;
  var url = ''.obs;
  var docs = ''.obs;
  
  var authType = 'inherit'.obs;
  var authConfig = <String, dynamic>{}.obs;
  
  var headers = <Map<String, dynamic>>[].obs;
  var queryParams = <Map<String, dynamic>>[].obs;
  
  var bodyType = 'none'.obs;
  var bodyFormat = 'json'.obs;
  var body = Rx<dynamic>('');

  // -- Original State (for unsaved changes check) --
  var originalMethod = 'GET';
  var originalUrl = '';
  var originalDocs = '';
  var originalAuthType = 'inherit';
  var originalAuthConfig = <String, dynamic>{};
  var originalHeaders = <Map<String, dynamic>>[];
  var originalQueryParams = <Map<String, dynamic>>[];
  var originalBodyType = 'none';
  var originalBodyFormat = 'json';
  dynamic originalBody = '';

  var hasUnsavedChanges = false.obs;
  
  final TextEditingController urlController = TextEditingController();
  
  var isLoading = false.obs;
  
  // -- Response State --
  var responseStatus = 0.obs;
  var responseTime = 0.obs;
  var responseSize = 0.obs;
  var responseData = ''.obs;
  
  var topPanelHeight = 300.0.obs;
  bool _isParsingUrl = false;

  @override
  void onInit() {
    super.onInit();
    
    urlController.addListener(() {
      if (_isParsingUrl) return;
      if (url.value != urlController.text) {
        url.value = urlController.text;
        syncUrlToParams();
      }
    });

    ever(url, (_) => _checkUnsavedChanges());
    ever(method, (_) => _checkUnsavedChanges());
    ever(docs, (_) => _checkUnsavedChanges());
    ever(authType, (_) => _checkUnsavedChanges());
    ever(authConfig, (_) => _checkUnsavedChanges());
    ever(headers, (_) => _checkUnsavedChanges());
    ever(queryParams, (_) => _checkUnsavedChanges());
    ever(bodyType, (_) => _checkUnsavedChanges());
    ever(bodyFormat, (_) => _checkUnsavedChanges());
    ever(body, (_) => _checkUnsavedChanges());
  }

  void syncUrlToParams() {
    if (_isParsingUrl) return;
    _isParsingUrl = true;
    
    final currentUrl = url.value;
    final queryIndex = currentUrl.indexOf('?');
    if (queryIndex == -1) {
      // Keep disabled params only
      final newParams = queryParams.where((p) => p['enabled'] == false).toList();
      queryParams.value = newParams;
    } else {
      final queryString = currentUrl.substring(queryIndex + 1);
      final pairs = queryString.split('&');
      
      final newParams = <Map<String, dynamic>>[];
      for (final pair in pairs) {
        if (pair.isEmpty) continue;
        final parts = pair.split('=');
        final key = parts[0];
        final value = parts.length > 1 ? parts.sublist(1).join('=') : '';
        
        final existing = queryParams.firstWhere((p) => p['key'] == Uri.decodeComponent(key) && p['enabled'] == true, orElse: () => <String, dynamic>{});
        
        newParams.add({
          'key': Uri.decodeComponent(key),
          'value': Uri.decodeComponent(value),
          'description': existing['description'] ?? '',
          'enabled': true,
        });
      }
      
      for (final p in queryParams) {
        if (p['enabled'] == false) {
          newParams.add(p);
        }
      }
      
      queryParams.value = newParams;
    }
    _isParsingUrl = false;
    _checkUnsavedChanges();
  }

  void syncParamsToUrl() {
    if (_isParsingUrl) return;
    _isParsingUrl = true;
    
    final baseUrl = url.value.split('?').first;
    final enabledParams = queryParams.where((p) => p['enabled'] == true && (p['key']?.toString().isNotEmpty == true || p['value']?.toString().isNotEmpty == true)).toList();
    
    if (enabledParams.isEmpty) {
      url.value = baseUrl;
      urlController.text = baseUrl;
    } else {
      final queryString = enabledParams.map((p) {
        final key = Uri.encodeComponent(p['key']?.toString() ?? '');
        final val = Uri.encodeComponent(p['value']?.toString() ?? '');
        return '$key=$val';
      }).join('&');
      
      final newUrl = '$baseUrl?$queryString';
      url.value = newUrl;
      urlController.text = newUrl;
    }
    
    _isParsingUrl = false;
    _checkUnsavedChanges();
  }

  void _checkUnsavedChanges() {
    if (currentRequestId.value == null) {
      hasUnsavedChanges.value = false;
      return;
    }
    
    bool changed = url.value != originalUrl || 
                   method.value != originalMethod ||
                   docs.value != originalDocs ||
                   authType.value != originalAuthType ||
                   bodyType.value != originalBodyType ||
                   bodyFormat.value != originalBodyFormat;
                   
    if (!changed) {
      changed = jsonEncode(authConfig) != jsonEncode(originalAuthConfig) ||
                jsonEncode(headers) != jsonEncode(originalHeaders) ||
                jsonEncode(queryParams) != jsonEncode(originalQueryParams) ||
                jsonEncode(body.value) != jsonEncode(originalBody);
    }
    
    hasUnsavedChanges.value = changed;
  }

  void loadRequest(Map<String, dynamic> request, {String path = 'Workspace > Collection'}) {
    _isParsingUrl = true; // prevent sync during load
    
    currentRequestId.value = request['_id'];
    currentPath.value = path;
    
    originalMethod = request['method'] ?? 'GET';
    originalUrl = request['url'] ?? '';
    originalDocs = request['docs'] ?? '';
    originalAuthType = request['authType'] ?? 'inherit';
    originalAuthConfig = request['authConfig'] ?? <String, dynamic>{};
    originalHeaders = List<Map<String, dynamic>>.from(request['headers'] ?? []);
    originalQueryParams = List<Map<String, dynamic>>.from(request['queryParams'] ?? []);
    originalBodyType = request['bodyType'] ?? 'none';
    originalBodyFormat = request['bodyFormat'] ?? 'json';
    originalBody = request['body'] ?? '';
    
    method.value = originalMethod;
    url.value = originalUrl;
    urlController.text = originalUrl;
    docs.value = originalDocs;
    authType.value = originalAuthType;
    authConfig.value = Map<String, dynamic>.from(originalAuthConfig);
    headers.value = List<Map<String, dynamic>>.from(originalHeaders);
    queryParams.value = List<Map<String, dynamic>>.from(originalQueryParams);
    bodyType.value = originalBodyType;
    bodyFormat.value = originalBodyFormat;
    body.value = originalBody;
    
    hasUnsavedChanges.value = false;
    _isParsingUrl = false;
    
    // Clear response pane
    responseStatus.value = 0;
    responseData.value = '';
    responseTime.value = 0;
    responseSize.value = 0;
  }

  void loadSavedResponse(Map<String, dynamic> request, Map<String, dynamic> response, {String path = 'Workspace > Collection'}) {
    loadRequest(request, path: path);
    responseStatus.value = response['status'] ?? 200;
    responseData.value = response['data'] ?? '';
    responseTime.value = response['time'] ?? 0;
    responseSize.value = response['size'] ?? 0;
  }

  Future<void> saveChanges() async {
    if (currentRequestId.value == null) return;
    
    try {
      await _apiService.updateRequest(currentRequestId.value!, {
        'url': url.value,
        'method': method.value,
        'docs': docs.value,
        'authType': authType.value,
        'authConfig': authConfig,
        'headers': headers,
        'queryParams': queryParams,
        'bodyType': bodyType.value,
        'bodyFormat': bodyFormat.value,
        'body': body.value,
      });
      
      originalUrl = url.value;
      originalMethod = method.value;
      originalDocs = docs.value;
      originalAuthType = authType.value;
      originalAuthConfig = Map<String, dynamic>.from(authConfig);
      originalHeaders = List<Map<String, dynamic>>.from(headers);
      originalQueryParams = List<Map<String, dynamic>>.from(queryParams);
      originalBodyType = bodyType.value;
      originalBodyFormat = bodyFormat.value;
      originalBody = body.value;
      
      hasUnsavedChanges.value = false;
      
      Get.find<WorkspaceController>().fetchCollections();
      
      log('Request saved', name: 'RequestBuilderController');
    } catch (e) {
      log('Failed to save request', error: e, name: 'RequestBuilderController');
      Get.snackbar('Error', 'Failed to save request');
    }
  }

  void sendRequest() async {
    if (url.value.isEmpty) {
      Get.snackbar('Error', 'URL cannot be empty');
      return;
    }

    if (hasUnsavedChanges.value) {
      await saveChanges();
    }
    
    isLoading.value = true;
    
    final dio = Dio();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Build Headers Map
      final requestHeaders = <String, dynamic>{};
      for (final h in headers) {
        if (h['enabled'] == true && h['key']?.toString().isNotEmpty == true) {
          requestHeaders[h['key']] = h['value'];
        }
      }
      
      // We are not compiling the body yet for sending, but this is a placeholder.
      // E.g., for raw body:
      dynamic requestBody;
      if (bodyType.value == 'raw') {
        requestBody = body.value;
        if (!requestHeaders.containsKey('Content-Type')) {
          if (bodyFormat.value == 'json') requestHeaders['Content-Type'] = 'application/json';
          else if (bodyFormat.value == 'xml') requestHeaders['Content-Type'] = 'application/xml';
          else requestHeaders['Content-Type'] = 'text/plain';
        }
      }
      // Note: for form-data or urlencoded, we'd compile the map here.
      
      final response = await dio.request(
        url.value,
        data: requestBody,
        options: Options(
          method: method.value,
          headers: requestHeaders,
        ),
      );
      
      stopwatch.stop();
      responseTime.value = stopwatch.elapsedMilliseconds;
      responseStatus.value = response.statusCode ?? 200;
      
      final dataString = response.data.toString();
      responseSize.value = dataString.length;
      
      try {
        if (response.data is Map || response.data is List) {
          responseData.value = const JsonEncoder.withIndent('  ').convert(response.data);
        } else {
          responseData.value = dataString;
        }
      } catch (_) {
        responseData.value = dataString;
      }
      
    } on DioException catch (e) {
      stopwatch.stop();
      responseTime.value = stopwatch.elapsedMilliseconds;
      responseStatus.value = e.response?.statusCode ?? 0;
      
      if (e.response?.data != null) {
        final errString = e.response!.data.toString();
        responseSize.value = errString.length;
        try {
          if (e.response!.data is Map || e.response!.data is List) {
            responseData.value = const JsonEncoder.withIndent('  ').convert(e.response!.data);
          } else {
            responseData.value = errString;
          }
        } catch (_) {
          responseData.value = errString;
        }
      } else {
        responseSize.value = 0;
        responseData.value = e.message ?? 'Unknown Error';
      }
    } catch (e) {
      stopwatch.stop();
      responseTime.value = stopwatch.elapsedMilliseconds;
      responseStatus.value = 0;
      responseSize.value = 0;
      responseData.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveResponse(String name) async {
    if (currentRequestId.value == null) {
      Get.snackbar('Error', 'Please save the request first.');
      return;
    }
    
    if (responseStatus.value == 0) {
      Get.snackbar('Error', 'No response to save. Please send the request first.');
      return;
    }

    try {
      await _apiService.saveResponse(currentRequestId.value!, {
        'name': name,
        'status': responseStatus.value,
        'data': responseData.value,
        'time': responseTime.value,
        'size': responseSize.value,
      });
      
      Get.snackbar('Success', 'Response saved successfully');
      
      // Refresh the sidebar to show the saved response
      Get.find<WorkspaceController>().fetchCollections();
    } catch (e) {
      log('Failed to save response', error: e, name: 'RequestBuilderController');
      Get.snackbar('Error', 'Failed to save response');
    }
  }
}
