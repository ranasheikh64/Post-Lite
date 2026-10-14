import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:postmanclone/app/data/providers/api_service.dart';
import 'package:postmanclone/app/data/providers/network_caller.dart';
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
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final workspaceController = Get.find<WorkspaceController>();
    final variables = workspaceController.getVariablesForRequest(
      reqController.currentRequestId.value ?? '',
    );

    List<TextSpan> spans = [];
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    int lastMatchEnd = 0;

    for (var match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }

      final varName = match.group(1)!;
      final isResolved = variables.containsKey(varName);

      spans.add(
        TextSpan(
          text: match.group(0),
          style: style?.copyWith(
            color: isResolved ? Colors.orange : Colors.redAccent,
          ),
        ),
      );

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
  var openRequests = <Map<String, dynamic>>[].obs;

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
  var formData = <Map<String, dynamic>>[].obs;
  var urlEncodedData = <Map<String, dynamic>>[].obs;
  var socketConfig = <String, dynamic>{}.obs;
  var socketEvents = <Map<String, dynamic>>[].obs;

  // -- Original State (for unsaved changes check) --
  var originalRequestKind = 'http';
  var originalMethod = 'GET';
  var originalUrl = '';
  var originalDocs = '';
  var originalAuthType = 'inherit';
  var originalAuthConfig = <String, dynamic>{};
  var originalHeaders = <Map<String, dynamic>>[];
  var originalQueryParams = <Map<String, dynamic>>[];
  var originalFormData = <Map<String, dynamic>>[];
  var originalUrlEncodedData = <Map<String, dynamic>>[];
  String originalBodyType = 'none';
  var originalBodyFormat = 'json';
  dynamic originalBody = '';
  var originalSocketConfig = <String, dynamic>{};
  var originalSocketEvents = <Map<String, dynamic>>[];
  var hasUnsavedChanges = false.obs;
  Timer? _autoSaveTimer;

  late final TextEditingController urlController =
      VariableTextEditingController(this);
  var isLoading = false.obs;

  // -- Response State --
  var responseStatus = 0.obs;
  var responseTime = 0.obs;
  var responseSize = 0.obs;
  var responseData = ''.obs;
  var isCopied = false.obs;

  String get statusMessage {
    final code = responseStatus.value;
    if (code >= 200 && code < 300) {
      if (code == 201) return 'Created';
      if (code == 202) return 'Accepted';
      if (code == 204) return 'No Content';
      return 'OK';
    }
    if (code == 301) return 'Moved Permanently';
    if (code == 302) return 'Found';
    if (code == 304) return 'Not Modified';
    if (code == 400) return 'Bad Request';
    if (code == 401) return 'Unauthorized';
    if (code == 403) return 'Forbidden';
    if (code == 404) return 'Not Found';
    if (code == 405) return 'Method Not Allowed';
    if (code == 409) return 'Conflict';
    if (code == 422) return 'Unprocessable Entity';
    if (code == 429) return 'Too Many Requests';
    if (code == 500) return 'Internal Server Error';
    if (code == 502) return 'Bad Gateway';
    if (code == 503) return 'Service Unavailable';
    if (code == 504) return 'Gateway Timeout';
    if (code == 0) return '';
    return '';
  }

  Color get statusColor {
    final code = responseStatus.value;
    if (code >= 200 && code < 300) return const Color(0xFF10B981);
    if (code >= 300 && code < 400) return const Color(0xFF3B82F6);
    if (code >= 400 && code < 500) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // -- Tabs Scroll Controller & Navigation --
  final ScrollController tabsScrollController = ScrollController();

  void scrollTabsLeft() {
    if (tabsScrollController.hasClients) {
      final target = (tabsScrollController.offset - 240).clamp(
        0.0,
        tabsScrollController.position.maxScrollExtent,
      );
      tabsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void scrollTabsRight() {
    if (tabsScrollController.hasClients) {
      final target = (tabsScrollController.offset + 240).clamp(
        0.0,
        tabsScrollController.position.maxScrollExtent,
      );
      tabsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    tabsScrollController.dispose();
    super.onClose();
  }

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
    ever(urlEncodedData, (_) => _checkUnsavedChanges());
    ever(socketConfig, (_) => _checkUnsavedChanges());
    ever(socketEvents, (_) => _checkUnsavedChanges());
  }

  List<Widget> getVariableTooltipWidgets() {
    final workspaceController = Get.find<WorkspaceController>();

    // Explicitly track collections to trigger Obx rebuilds when variables update
    workspaceController.collections.isEmpty;

    final variables = workspaceController.getVariableDetailsForRequest(
      currentRequestId.value ?? '',
    );

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
      widgets.add(
        VariableHoverCard(
          varName: varName,
          detail: detail,
          requestId: currentRequestId.value,
        ),
      );
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
        final newUrlEncoded = urlEncodedData
            .where((p) => p['enabled'] == false)
            .toList();
        urlEncodedData.value = newUrlEncoded;

        final newSocketEvents = socketEvents
            .where((p) => p['enabled'] == false)
            .toList();
        socketEvents.value = newSocketEvents;
      } else {
        final queryString = currentUrl.substring(queryIndex + 1);
        final pairs = queryString.split('&');

        final newParams = <Map<String, dynamic>>[];
        for (final pair in pairs) {
          if (pair.isEmpty) continue;
          final parts = pair.split('=');
          final key = parts[0];
          final value = parts.length > 1 ? parts.sublist(1).join('=') : '';

          final existing = queryParams.firstWhere(
            (p) => p['key'] == Uri.decodeComponent(key) && p['enabled'] == true,
            orElse: () => <String, dynamic>{},
          );

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
      log(
        'Error syncing URL to Params',
        error: e,
        name: 'RequestBuilderController',
      );
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
      final enabledParams = queryParams
          .where(
            (p) =>
                p['enabled'] == true &&
                (p['key']?.toString().isNotEmpty == true ||
                    p['value']?.toString().isNotEmpty == true),
          )
          .toList();

      if (enabledParams.isEmpty) {
        url.value = baseUrl;
        if (urlController.text != baseUrl) {
          urlController.text = baseUrl;
        }
      } else {
        final queryString = enabledParams
            .map((p) {
              final key = Uri.encodeComponent(
                (p['key']?.toString() ?? '').trim(),
              );
              final val = Uri.encodeComponent(
                (p['value']?.toString() ?? '').trim(),
              );
              return '$key=$val';
            })
            .join('&');

        final newUrl = '$baseUrl?$queryString';
        url.value = newUrl;
        if (urlController.text != newUrl) {
          urlController.text = newUrl;
        }
      }
    } catch (e) {
      log(
        'Error syncing Params to URL',
        error: e,
        name: 'RequestBuilderController',
      );
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

    bool changed =
        url.value != originalUrl ||
        method.value != originalMethod ||
        docs.value != originalDocs ||
        authType.value != originalAuthType ||
        bodyType.value != originalBodyType ||
        bodyFormat.value != originalBodyFormat ||
        jsonEncode(urlEncodedData) != jsonEncode(originalUrlEncodedData) ||
        jsonEncode(socketConfig) != jsonEncode(originalSocketConfig) ||
        jsonEncode(socketEvents) != jsonEncode(originalSocketEvents);

    if (!changed) {
      final currentBodyPayload = {
        'raw': body.value,
        'formData': formData
            .where(
              (p) =>
                  p['key']?.toString().isNotEmpty == true ||
                  p['value']?.toString().isNotEmpty == true ||
                  p['description']?.toString().isNotEmpty == true,
            )
            .toList(),
        'urlEncodedData': urlEncodedData
            .where(
              (p) =>
                  p['key']?.toString().isNotEmpty == true ||
                  p['value']?.toString().isNotEmpty == true ||
                  p['description']?.toString().isNotEmpty == true,
            )
            .toList(),
      };

      changed =
          jsonEncode(authConfig) != jsonEncode(originalAuthConfig) ||
          jsonEncode(headers) != jsonEncode(originalHeaders) ||
          jsonEncode(queryParams) != jsonEncode(originalQueryParams) ||
          jsonEncode(currentBodyPayload) != jsonEncode(originalBody);
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

  void loadRequest(
    Map<String, dynamic> request, {
    String path = 'Workspace > Collection',
  }) {
    _isParsingUrl = true; // prevent sync during load

    currentRequestId.value = request['_id'];
    currentPath.value = path;

    bool exists = openRequests.any((req) => req['_id'] == request['_id']);
    if (!exists) {
      openRequests.add(Map<String, dynamic>.from(request));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (tabsScrollController.hasClients) {
          tabsScrollController.animateTo(
            tabsScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    _finishLoadRequest(request);
  }

  void updateOpenRequestName(String reqId, String newName) {
    for (var i = 0; i < openRequests.length; i++) {
      if (openRequests[i]['_id'] == reqId) {
        openRequests[i]['name'] = newName;
        openRequests.refresh();
        break;
      }
    }
  }

  void closeOtherRequests(String id) {
    openRequests.removeWhere((req) => req['_id'] != id);
    if (currentRequestId.value != id && openRequests.isNotEmpty) {
      final req = openRequests.first;
      loadRequest(req, path: 'Recent > ${req['name']}');
    }
  }

  void closeRequestsToRight(String id) {
    int idx = openRequests.indexWhere((req) => req['_id'] == id);
    if (idx != -1 && idx < openRequests.length - 1) {
      final toRemove = openRequests.sublist(idx + 1).map((r) => r['_id']).toSet();
      openRequests.removeRange(idx + 1, openRequests.length);
      if (toRemove.contains(currentRequestId.value)) {
        if (openRequests.isNotEmpty) {
          final req = openRequests.last;
          loadRequest(req, path: 'Recent > ${req['name']}');
        } else {
          currentRequestId.value = null;
        }
      }
    }
  }

  void closeRequestsToLeft(String id) {
    int idx = openRequests.indexWhere((req) => req['_id'] == id);
    if (idx > 0) {
      final toRemove = openRequests.sublist(0, idx).map((r) => r['_id']).toSet();
      openRequests.removeRange(0, idx);
      if (toRemove.contains(currentRequestId.value)) {
        if (openRequests.isNotEmpty) {
          final req = openRequests.first;
          loadRequest(req, path: 'Recent > ${req['name']}');
        } else {
          currentRequestId.value = null;
        }
      }
    }
  }

  void reorderRequests(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final req = openRequests.removeAt(oldIndex);
    openRequests.insert(newIndex, req);
  }

  void _finishLoadRequest(Map<String, dynamic> request) {

    originalRequestKind = request['requestKind'] ?? 'http';
    originalMethod = request['method'] ?? 'GET';
    originalUrl = request['url'] ?? '';
    originalDocs = request['docs'] ?? '';
    originalAuthType = request['authType'] ?? 'inherit';
    originalAuthConfig = request['authConfig'] ?? <String, dynamic>{};
    originalHeaders = List<Map<String, dynamic>>.from(request['headers'] ?? []);
    originalQueryParams = List<Map<String, dynamic>>.from(
      request['queryParams'] ?? [],
    );
    originalBodyType = request['bodyType'] ?? 'none';
    originalBodyFormat =
        (request['bodyFormat'] ?? 'json').toString().toLowerCase();
    originalBody = request['body'] ?? '';
    originalSocketConfig = request['socketConfig'] ?? <String, dynamic>{};

    if (originalSocketConfig['events'] is List) {
      originalSocketEvents = (originalSocketConfig['events'] as List)
          .map(
            (e) => {
              'key': e.toString(),
              'value': '',
              'description': '',
              'enabled': true,
            },
          )
          .toList();
    } else {
      originalSocketEvents = [];
    }

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

    if (originalBody is Map && originalBody.containsKey('raw')) {
      body.value = originalBody['raw'] ?? '';

      if (originalBody['formData'] is List) {
        originalFormData = List<Map<String, dynamic>>.from(
          originalBody['formData'].map((e) => Map<String, dynamic>.from(e)),
        );
      } else {
        originalFormData = [];
      }
      formData.assignAll(originalFormData);

      if (originalBody['urlEncodedData'] is List) {
        originalUrlEncodedData = List<Map<String, dynamic>>.from(
          originalBody['urlEncodedData'].map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      } else {
        originalUrlEncodedData = [];
      }
      urlEncodedData.assignAll(originalUrlEncodedData);
    } else {
      if (originalBodyType == 'form-data') {
        if (originalBody is List) {
          originalFormData = List<Map<String, dynamic>>.from(
            originalBody.map((e) => Map<String, dynamic>.from(e)),
          );
        } else {
          originalFormData = [];
        }
        formData.assignAll(originalFormData);
        urlEncodedData.clear();
        body.value = '';
      } else if (originalBodyType == 'urlencoded' ||
          originalBodyType == 'x-www-form-urlencoded') {
        if (originalBody is List) {
          originalUrlEncodedData = List<Map<String, dynamic>>.from(
            originalBody.map((e) => Map<String, dynamic>.from(e)),
          );
        } else {
          originalUrlEncodedData = [];
        }
        urlEncodedData.assignAll(originalUrlEncodedData);
        formData.clear();
        body.value = '';
      } else {
        body.value = originalBody;
        formData.clear();
        urlEncodedData.clear();
        originalFormData = [];
        originalUrlEncodedData = [];
      }
    }

    socketConfig.value = Map<String, dynamic>.from(originalSocketConfig);
    socketEvents.value = List<Map<String, dynamic>>.from(
      originalSocketEvents.map((e) => Map<String, dynamic>.from(e)),
    );

    hasUnsavedChanges.value = false;
    _isParsingUrl = false;

    // Clear response pane
    responseStatus.value = 0;
    responseData.value = '';
    responseTime.value = 0;
    responseSize.value = 0;
  }

  void loadSavedResponse(
    Map<String, dynamic> request,
    Map<String, dynamic> response, {
    String path = 'Workspace > Collection',
  }) {
    loadRequest(request, path: path);
    responseStatus.value = response['status'] ?? 200;
    responseData.value = response['data'] ?? '';
    responseTime.value = response['time'] ?? 0;
    responseSize.value = response['size'] ?? 0;
  }

  Future<void> saveChanges({bool isAutoSave = false}) async {
    if (currentRequestId.value == null) return;

    try {
      final cleanQueryParams = queryParams
          .where(
            (p) =>
                p['key']?.toString().isNotEmpty == true ||
                p['value']?.toString().isNotEmpty == true ||
                p['description']?.toString().isNotEmpty == true,
          )
          .toList();
      final cleanHeaders = headers
          .where(
            (h) =>
                h['key']?.toString().isNotEmpty == true ||
                h['value']?.toString().isNotEmpty == true ||
                h['description']?.toString().isNotEmpty == true,
          )
          .toList();

      final cleanFormData = formData
          .where(
            (p) =>
                p['key']?.toString().isNotEmpty == true ||
                p['value']?.toString().isNotEmpty == true ||
                p['description']?.toString().isNotEmpty == true,
          )
          .toList();
      final cleanUrlEncodedData = urlEncodedData
          .where(
            (p) =>
                p['key']?.toString().isNotEmpty == true ||
                p['value']?.toString().isNotEmpty == true ||
                p['description']?.toString().isNotEmpty == true,
          )
          .toList();
      final cleanSocketEvents = socketEvents
          .where(
            (p) =>
                p['enabled'] == true &&
                (p['key']?.toString().isNotEmpty ?? false),
          )
          .map((p) => p['key'].toString())
          .toList();

      final bodyPayload = {
        'raw': body.value,
        'formData': cleanFormData,
        'urlEncodedData': cleanUrlEncodedData,
      };

      final updateData = {
        'url': url.value,
        'method': method.value,
        'docs': docs.value,
        'authType': authType.value,
        'authConfig': authConfig,
        'headers': cleanHeaders,
        'queryParams': cleanQueryParams,
        'bodyType': bodyType.value == 'x-www-form-urlencoded'
            ? 'urlencoded'
            : bodyType.value,
        'bodyFormat': bodyFormat.value,
        'body': bodyPayload,
        'socketConfig': {...socketConfig, 'events': cleanSocketEvents},
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
      originalBody = bodyPayload;
      originalFormData = List<Map<String, dynamic>>.from(formData);
      originalUrlEncodedData = List<Map<String, dynamic>>.from(urlEncodedData);
      originalSocketConfig = Map<String, dynamic>.from(socketConfig);
      originalSocketConfig['events'] = cleanSocketEvents;
      originalSocketEvents = List<Map<String, dynamic>>.from(
        socketEvents.map((e) => Map<String, dynamic>.from(e)),
      );

      hasUnsavedChanges.value = false;

      if (!isAutoSave) {
        Get.find<WorkspaceController>().fetchCollections();
      } else {
        Get.find<WorkspaceController>().updateRequestLocally(
          currentRequestId.value!,
          updateData,
        );
      }

      log('Request saved', name: 'RequestBuilderController');
    } catch (e) {
      log('Failed to save request', error: e, name: 'RequestBuilderController');
      if (!isAutoSave) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'Failed to save request',
          isError: true,
        );
      }
    }
  }

  void sendRequest() async {
    if (url.value.isEmpty) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'URL cannot be empty',
        isError: true,
      );
      return;
    }

    if (hasUnsavedChanges.value) {
      await saveChanges();
    }

    isLoading.value = true;

    final dio = Dio();
    final stopwatch = Stopwatch()..start();
    String resolvedUrl = '';

    try {
      final workspaceController = Get.find<WorkspaceController>();
      final variables = workspaceController.getVariablesForRequest(
        currentRequestId.value ?? '',
      );

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
            if (jsonString[i] == '*' &&
                i + 1 < jsonString.length &&
                jsonString[i + 1] == '/') {
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

      resolvedUrl = resolveVariables(url.value).trim();

      // Build Headers Map
      final requestHeaders = <String, dynamic>{};
      for (final h in headers) {
        if (h['enabled'] == true && h['key']?.toString().isNotEmpty == true) {
          requestHeaders[resolveVariables(h['key'])] = resolveVariables(
            h['value'] ?? '',
          );
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
        final rawText = body.value;
        final currentFormat = bodyFormat.value.toLowerCase();

        if (rawText.trim().isEmpty) {
          requestBody = null;
        } else if (currentFormat == 'json') {
          final cleanJson = stripJsonComments(rawText);
          try {
            // Verify that it is valid JSON before sending to prevent 500 API errors
            requestBody = jsonDecode(resolveVariables(cleanJson));
          } catch (e) {
            isLoading.value = false;
            CustomSnackbar.show(
              title: 'Invalid JSON',
              message:
                  'Your JSON payload contains syntax errors or invalid formatting.',
              isError: true,
            );
            return;
          }
        } else {
          // text, html, xml, javascript - sent as resolved string body
          requestBody = resolveVariables(rawText);
        }

        final hasContentType = requestHeaders.keys.any(
          (k) => k.toLowerCase() == 'content-type',
        );
        if (!hasContentType) {
          switch (currentFormat) {
            case 'json':
              requestHeaders['Content-Type'] = 'application/json';
              break;
            case 'xml':
              requestHeaders['Content-Type'] = 'application/xml';
              break;
            case 'html':
              requestHeaders['Content-Type'] = 'text/html';
              break;
            case 'javascript':
              requestHeaders['Content-Type'] = 'application/javascript';
              break;
            case 'text':
            default:
              requestHeaders['Content-Type'] = 'text/plain';
              break;
          }
        }
      } else if (bodyType.value == 'form-data') {
        final fd = FormData();
        for (var item in formData) {
          if (item['enabled'] == true &&
              item['key']?.toString().isNotEmpty == true) {
            final key = resolveVariables(item['key']);
            if (item['type'] == 'file' &&
                item['value']?.toString().isNotEmpty == true) {
              final filePath = resolveVariables(item['value']);
              final fileName = filePath.split('/').last;
              fd.files.add(
                MapEntry(
                  key,
                  await MultipartFile.fromFile(filePath, filename: fileName),
                ),
              );
            } else {
              fd.fields.add(
                MapEntry(key, resolveVariables(item['value'] ?? '')),
              );
            }
          }
        }
        requestBody = fd;
      } else if (bodyType.value == 'x-www-form-urlencoded' ||
          bodyType.value == 'urlencoded') {
        final map = <String, String>{};
        for (var item in urlEncodedData) {
          if (item['enabled'] == true &&
              item['key']?.toString().isNotEmpty == true) {
            map[resolveVariables(item['key'])] = resolveVariables(
              item['value'] ?? '',
            );
          }
        }
        requestBody = map;
        final hasContentType = requestHeaders.keys.any(
          (k) => k.toLowerCase() == 'content-type',
        );
        if (!hasContentType) {
          requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
        }
      } else if (bodyType.value == 'graphql') {
        final rawText = body.value;
        if (rawText.trim().isNotEmpty) {
          try {
            final parsed = jsonDecode(rawText);
            if (parsed is Map && parsed.containsKey('query')) {
              requestBody = parsed;
            } else {
              requestBody = {'query': resolveVariables(rawText)};
            }
          } catch (_) {
            requestBody = {'query': resolveVariables(rawText)};
          }
        } else {
          requestBody = {'query': ''};
        }
        final hasContentType = requestHeaders.keys.any(
          (k) => k.toLowerCase() == 'content-type',
        );
        if (!hasContentType) {
          requestHeaders['Content-Type'] = 'application/json';
        }
      } else if (bodyType.value == 'binary') {
        final rawText = body.value;
        if (rawText.trim().isNotEmpty) {
          requestBody = resolveVariables(rawText);
        }
        final hasContentType = requestHeaders.keys.any(
          (k) => k.toLowerCase() == 'content-type',
        );
        if (!hasContentType) {
          requestHeaders['Content-Type'] = 'application/octet-stream';
        }
      }

      bool isLocalhost(String urlStr) {
        try {
          final uri = Uri.parse(urlStr);
          final host = uri.host.toLowerCase();
          return host == 'localhost' ||
              host == '127.0.0.1' ||
              host == '0.0.0.0' ||
              host == '::1' ||
              host.endsWith('.localhost');
        } catch (_) {
          return urlStr.contains('localhost') || urlStr.contains('127.0.0.1');
        }
      }

      // Check if running on Web and attempting to access localhost via remote cloud proxy
      if (kIsWeb && isLocalhost(resolvedUrl)) {
        stopwatch.stop();
        responseTime.value = stopwatch.elapsedMilliseconds;
        responseStatus.value = 0;
        final errorPayload = {
          "error": "Localhost Not Accessible via Web Browser",
          "message":
              "You are running Post-Lite in a Web Browser. Remote cloud proxies (Vercel) cannot connect to 'localhost' or '127.0.0.1' on your local computer.",
          "how_to_test_localhost": [
            "🖥️ Desktop App (Recommended): Run the Post-Lite Desktop App (macOS, Windows, Linux) to test localhost directly with 0 setup and no CORS.",
            "🌐 Ngrok Tunnel: Expose your local port via 'npx ngrok http <port>' (e.g. npx ngrok http 5000) and test the public https ngrok URL.",
            "💻 Local Backend: Run the Post-Lite backend server locally on your machine and set baseUrl to 'http://localhost:4000'."
          ]
        };
        final prettyNotice =
            const JsonEncoder.withIndent('  ').convert(errorPayload);
        responseData.value = prettyNotice;
        responseSize.value = prettyNotice.length;

        CustomSnackbar.show(
          title: 'Localhost not supported on Web',
          message:
              'Cloud proxy cannot reach your local machine. Please run the Desktop app or use ngrok.',
          isError: true,
        );
        return;
      }

      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      dynamic actualData;
      int statusCode = 200;

      if (kIsWeb) {
        // Route through proxy on Web to bypass browser CORS limitations
        final proxyUrl = '${NetworkCaller().baseUrl}/proxy';
        final isFormData = requestBody is FormData;
        dynamic proxyData;

        if (isFormData) {
          final fd = requestBody;
          fd.fields.add(MapEntry('Proxy-Method', method.value));
          fd.fields.add(MapEntry('Proxy-Url', resolvedUrl));
          fd.fields.add(MapEntry('Proxy-Headers', jsonEncode(requestHeaders)));
          proxyData = fd;
        } else {
          proxyData = {
            'method': method.value,
            'url': resolvedUrl,
            'headers': requestHeaders,
            'body': requestBody,
          };
        }

        final proxyResponse = await dio.post(proxyUrl, data: proxyData);
        statusCode = proxyResponse.data['status'] ?? 200;
        actualData = proxyResponse.data['data'];
      } else {
        // Direct request on Desktop (macOS, Windows, Linux) and Mobile
        // No CORS restrictions, direct localhost and local network access
        final response = await dio.request(
          resolvedUrl,
          data: requestBody,
          options: Options(
            method: method.value,
            headers: requestHeaders,
            validateStatus: (status) => true, // Accept 2xx, 3xx, 4xx, 5xx as valid responses
          ),
        );
        statusCode = response.statusCode ?? 200;
        actualData = response.data;
      }

      stopwatch.stop();
      responseTime.value = stopwatch.elapsedMilliseconds;
      responseStatus.value = statusCode;

      final dataString = actualData != null
          ? (actualData is String ? actualData : jsonEncode(actualData))
          : '';
      responseSize.value = dataString.length;

      try {
        if (actualData is Map || actualData is List) {
          responseData.value = const JsonEncoder.withIndent(
            '  ',
          ).convert(actualData);
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
        final errData = e.response!.data;
        final errString = errData is String ? errData : jsonEncode(errData);
        responseSize.value = errString.length;
        try {
          if (errData is Map || errData is List) {
            responseData.value = const JsonEncoder.withIndent(
              '  ',
            ).convert(errData);
          } else {
            responseData.value = errString;
          }
        } catch (_) {
          responseData.value = errString;
        }
      } else {
        final isLocal = resolvedUrl.contains('localhost') ||
            resolvedUrl.contains('127.0.0.1');
        final errorPayload = {
          "error": "Could not connect to server",
          "url": resolvedUrl,
          "details": e.message ?? "Connection refused or unreachable",
          "hint": isLocal
              ? "Make sure your local server is actively running on port ${Uri.tryParse(resolvedUrl)?.port ?? ''}."
              : "Check your internet connection and verify that the target URL is valid and reachable."
        };
        final prettyErr =
            const JsonEncoder.withIndent('  ').convert(errorPayload);
        responseSize.value = prettyErr.length;
        responseData.value = prettyErr;
        CustomSnackbar.show(
          title: 'Connection Failed',
          message: isLocal
              ? 'Could not connect to $resolvedUrl. Make sure your local server is running.'
              : (e.message ?? 'Failed to connect to server'),
          isError: true,
        );
      }
    } catch (e) {
      stopwatch.stop();
      responseTime.value = stopwatch.elapsedMilliseconds;
      responseStatus.value = 0;
      responseSize.value = 0;
      responseData.value = e.toString();
      CustomSnackbar.show(
        title: 'Request Failed',
        message: e.toString(),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveResponse(String name) async {
    if (currentRequestId.value == null) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'Please save the request first.',
        isError: true,
      );
      return;
    }

    if (responseStatus.value == 0) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'No response to save. Please send the request first.',
        isError: true,
      );
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

      CustomSnackbar.show(
        title: 'Success',
        message: 'Response saved successfully',
      );

      // Refresh the sidebar to show the saved response
      Get.find<WorkspaceController>().fetchCollections();
    } catch (e) {
      log(
        'Failed to save response',
        error: e,
        name: 'RequestBuilderController',
      );
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to save response',
        isError: true,
      );
    }
  }
}
