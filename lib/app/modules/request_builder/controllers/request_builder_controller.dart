import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/data/providers/api_service.dart';
import 'dart:developer';
import 'dart:convert';
import 'dart:async';

import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/widgets/variable_hover_card.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';


class VariableTextEditingController extends TextEditingController {
  final RequestBuilderController reqController;

  VariableTextEditingController(this.reqController);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final workspaceController = Get.find<WorkspaceController>();
    final variables = workspaceController.getVariablesForRequest(reqController.currentRequestId.value ?? '');
    
    List<TextSpan> spans = [];
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    int lastMatchEnd = 0;
    
    for (var match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: style));
      }
      
      final varName = match.group(1)!;
      final isResolved = variables.containsKey(varName);
      
      spans.add(TextSpan(
        text: match.group(0),
        style: style?.copyWith(
          color: isResolved ? Colors.orange : Colors.redAccent,
        ),
      ));
      
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }
    
    return TextSpan(style: style, children: spans);
  }
}

class RequestBuilderController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var currentRequestId = RxnString();
  var currentPath = 'Workspace > Collection'.obs;
  
  // -- Request State --
  var requestKind = 'http'.obs;
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
  
  var socketConfig = <String, dynamic>{}.obs;

  // -- Original State (for unsaved changes check) --
  var originalRequestKind = 'http';
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
  var originalSocketConfig = <String, dynamic>{};

  var hasUnsavedChanges = false.obs;
  Timer? _autoSaveTimer;
  
  late final TextEditingController urlController = VariableTextEditingController(this);
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
    ever(socketConfig, (_) => _checkUnsavedChanges());
  }
  
  List<Widget> getVariableTooltipWidgets() {
    final workspaceController = Get.find<WorkspaceController>();
    
    // Explicitly track collections to trigger Obx rebuilds when variables update
    workspaceController.collections.isEmpty;
    
    final variables = workspaceController.getVariableDetailsForRequest(currentRequestId.value ?? '');
    
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(urlController.text);
    
    if (matches.isEmpty) return [];
    
    final Set<String> uniqueVars = {};
    for (var match in matches) {
      uniqueVars.add(match.group(1)!);
    }
    
    List<Widget> widgets = [];
    for (var varName in uniqueVars) {
      final detail = variables[varName];
      widgets.add(VariableHoverCard(varName: varName, detail: detail, requestId: currentRequestId.value));
    }
    
    return widgets;
  }

  void syncUrlToParams() {
    if (_isParsingUrl) return;
    _isParsingUrl = true;
    
    try {
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
    } catch (e) {
      log('Error syncing URL to Params', error: e, name: 'RequestBuilderController');
    } finally {
      _isParsingUrl = false;
      _checkUnsavedChanges();
    }
  }

  void syncParamsToUrl() {
    if (_isParsingUrl) return;
    _isParsingUrl = true;
    
    try {
      final baseUrl = url.value.split('?').first;
      final enabledParams = queryParams.where((p) => p['enabled'] == true && (p['key']?.toString().isNotEmpty == true || p['value']?.toString().isNotEmpty == true)).toList();
      
      if (enabledParams.isEmpty) {
        url.value = baseUrl;
        if (urlController.text != baseUrl) {
          urlController.text = baseUrl;
        }
      } else {
        final queryString = enabledParams.map((p) {
          final key = Uri.encodeComponent(p['key']?.toString() ?? '');
          final val = Uri.encodeComponent(p['value']?.toString() ?? '');
          return '$key=$val';
        }).join('&');
        
        final newUrl = '$baseUrl?$queryString';
        url.value = newUrl;
        if (urlController.text != newUrl) {
          urlController.text = newUrl;
        }
      }
    } catch (e) {
      log('Error syncing Params to URL', error: e, name: 'RequestBuilderController');
    } finally {
      _isParsingUrl = false;
      _checkUnsavedChanges();
    }
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
                   bodyFormat.value != originalBodyFormat ||
                   jsonEncode(socketConfig) != jsonEncode(originalSocketConfig);
                   
    if (!changed) {
      changed = jsonEncode(authConfig) != jsonEncode(originalAuthConfig) ||
                jsonEncode(headers) != jsonEncode(originalHeaders) ||
                jsonEncode(queryParams) != jsonEncode(originalQueryParams) ||
                jsonEncode(body.value) != jsonEncode(originalBody);
    }
    
    hasUnsavedChanges.value = changed;
    
    if (changed) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(milliseconds: 1000), () {
        if (hasUnsavedChanges.value) {
          saveChanges(isAutoSave: true);
        }
      });
    }
  }

  void loadRequest(Map<String, dynamic> request, {String path = 'Workspace > Collection'}) {
    _isParsingUrl = true; // prevent sync during load
    
    currentRequestId.value = request['_id'];
    currentPath.value = path;
    
    originalRequestKind = request['requestKind'] ?? 'http';
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
    originalSocketConfig = request['socketConfig'] ?? <String, dynamic>{};
    
    requestKind.value = originalRequestKind;
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
    socketConfig.value = Map<String, dynamic>.from(originalSocketConfig);
    
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

  Future<void> saveChanges({bool isAutoSave = false}) async {
    if (currentRequestId.value == null) return;
    
    try {
      final cleanQueryParams = queryParams.where((p) => p['key']?.toString().isNotEmpty == true || p['value']?.toString().isNotEmpty == true || p['description']?.toString().isNotEmpty == true).toList();
      final cleanHeaders = headers.where((h) => h['key']?.toString().isNotEmpty == true || h['value']?.toString().isNotEmpty == true || h['description']?.toString().isNotEmpty == true).toList();

      final updateData = {
        'url': url.value,
        'method': method.value,
        'docs': docs.value,
        'authType': authType.value,
        'authConfig': authConfig,
        'headers': cleanHeaders,
        'queryParams': cleanQueryParams,
        'bodyType': bodyType.value,
        'bodyFormat': bodyFormat.value,
        'body': body.value,
        'socketConfig': socketConfig,
      };

      await _apiService.updateRequest(currentRequestId.value!, updateData);
      
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
      originalSocketConfig = Map<String, dynamic>.from(socketConfig);
      
      hasUnsavedChanges.value = false;
      
      if (!isAutoSave) {
        Get.find<WorkspaceController>().fetchCollections();
      } else {
        Get.find<WorkspaceController>().updateRequestLocally(currentRequestId.value!, updateData);
      }
      
      log('Request saved', name: 'RequestBuilderController');
    } catch (e) {
      log('Failed to save request', error: e, name: 'RequestBuilderController');
      if (!isAutoSave) {
        CustomSnackbar.show(title: 'Error', message: 'Failed to save request', isError: true);
      }
    }
  }

  void sendRequest() async {
    if (url.value.isEmpty) {
      CustomSnackbar.show(title: 'Error', message: 'URL cannot be empty', isError: true);
      return;
    }

    if (hasUnsavedChanges.value) {
      await saveChanges();
    }
    
    isLoading.value = true;
    
    final dio = Dio();
    final stopwatch = Stopwatch()..start();
    
    try {
      final workspaceController = Get.find<WorkspaceController>();
      final variables = workspaceController.getVariablesForRequest(currentRequestId.value ?? '');
      
      String resolveVariables(String input) {
        if (input.isEmpty) return input;
        String output = input;
        variables.forEach((key, value) {
          output = output.replaceAll('{{$key}}', value);
        });
        return output;
      }

      String stripJsonComments(String jsonString) {
        bool inString = false;
        bool inSingleComment = false;
        bool inMultiComment = false;
        StringBuffer result = StringBuffer();
        for (int i = 0; i < jsonString.length; i++) {
          if (inSingleComment) {
            if (jsonString[i] == '\n') {
              inSingleComment = false;
              result.write('\n');
            }
            continue;
          }
          if (inMultiComment) {
            if (jsonString[i] == '*' && i + 1 < jsonString.length && jsonString[i + 1] == '/') {
              inMultiComment = false;
              i++; // skip '/'
            }
            continue;
          }
          if (jsonString[i] == '"' && (i == 0 || jsonString[i - 1] != '\\')) {
            inString = !inString;
          }
          if (!inString && jsonString[i] == '/' && i + 1 < jsonString.length) {
            if (jsonString[i + 1] == '/') {
              inSingleComment = true;
              i++;
              continue;
            } else if (jsonString[i + 1] == '*') {
              inMultiComment = true;
              i++;
              continue;
            }
          }
          result.write(jsonString[i]);
        }
        return result.toString();
      }
      
      final resolvedUrl = resolveVariables(url.value);

      // Build Headers Map
      final requestHeaders = <String, dynamic>{};
      for (final h in headers) {
        if (h['enabled'] == true && h['key']?.toString().isNotEmpty == true) {
          requestHeaders[resolveVariables(h['key'])] = resolveVariables(h['value'] ?? '');
        }
      }

      // Handle Authentication
      if (authType.value == 'bearer') {
        final token = resolveVariables(authConfig['token'] ?? '');
        if (token.isNotEmpty) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      } else if (authType.value == 'basic') {
        final username = resolveVariables(authConfig['username'] ?? '');
        final password = resolveVariables(authConfig['password'] ?? '');
        if (username.isNotEmpty || password.isNotEmpty) {
          final credentials = '$username:$password';
          final base64Credentials = base64Encode(utf8.encode(credentials));
          requestHeaders['Authorization'] = 'Basic $base64Credentials';
        }
      }
      
      // Build Request Body
      dynamic requestBody;
      if (bodyType.value == 'raw') {
        String rawText = body.value;
        if (bodyFormat.value == 'json') {
          rawText = stripJsonComments(rawText);
        }
        requestBody = resolveVariables(rawText);

        if (!requestHeaders.containsKey('Content-Type')) {
          if (bodyFormat.value == 'json') requestHeaders['Content-Type'] = 'application/json';
          else if (bodyFormat.value == 'xml') requestHeaders['Content-Type'] = 'application/xml';
          else requestHeaders['Content-Type'] = 'text/plain';
        }
      }
      // Note: for form-data or urlencoded, we'd compile the map here.
      
      final response = await dio.request(
        resolvedUrl,
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
      CustomSnackbar.show(title: 'Error', message: 'Please save the request first.', isError: true);
      return;
    }
    
    if (responseStatus.value == 0) {
      CustomSnackbar.show(title: 'Error', message: 'No response to save. Please send the request first.', isError: true);
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
      
      CustomSnackbar.show(title: 'Success', message: 'Response saved successfully');
      
      // Refresh the sidebar to show the saved response
      Get.find<WorkspaceController>().fetchCollections();
    } catch (e) {
      log('Failed to save response', error: e, name: 'RequestBuilderController');
      CustomSnackbar.show(title: 'Error', message: 'Failed to save response', isError: true);
    }
  }
}
