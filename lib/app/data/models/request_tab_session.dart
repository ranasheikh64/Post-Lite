class RequestTabSession {
  final String id;
  String name, path, requestKind, method, url, docs, authType;
  Map<String, dynamic> authConfig;
  List<Map<String, dynamic>> headers, queryParams;
  String bodyType, bodyFormat;
  dynamic body;
  List<Map<String, dynamic>> formData, urlEncodedData;
  Map<String, dynamic> socketConfig;
  List<Map<String, dynamic>> socketEvents;

  String originalRequestKind, originalMethod, originalUrl, originalDocs, originalAuthType;
  Map<String, dynamic> originalAuthConfig;
  List<Map<String, dynamic>> originalHeaders, originalQueryParams;
  String originalBodyType, originalBodyFormat;
  dynamic originalBody;
  List<Map<String, dynamic>> originalFormData, originalUrlEncodedData;
  Map<String, dynamic> originalSocketConfig;
  List<Map<String, dynamic>> originalSocketEvents;

  bool hasUnsavedChanges;
  int responseStatus, responseTime, responseSize;
  String responseData;

  RequestTabSession({
    required this.id,
    required this.name,
    this.path = 'Workspace > Collection',
    this.requestKind = 'http',
    this.method = 'GET',
    this.url = '',
    this.docs = '',
    this.authType = 'inherit',
    required this.authConfig,
    required this.headers,
    required this.queryParams,
    this.bodyType = 'none',
    this.bodyFormat = 'json',
    this.body = '',
    required this.formData,
    required this.urlEncodedData,
    required this.socketConfig,
    required this.socketEvents,
    this.originalRequestKind = 'http',
    this.originalMethod = 'GET',
    this.originalUrl = '',
    this.originalDocs = '',
    this.originalAuthType = 'inherit',
    required this.originalAuthConfig,
    required this.originalHeaders,
    required this.originalQueryParams,
    this.originalBodyType = 'none',
    this.originalBodyFormat = 'json',
    this.originalBody = '',
    required this.originalFormData,
    required this.originalUrlEncodedData,
    required this.originalSocketConfig,
    required this.originalSocketEvents,
    this.hasUnsavedChanges = false,
    this.responseStatus = 0,
    this.responseTime = 0,
    this.responseSize = 0,
    this.responseData = '',
  });

  factory RequestTabSession.fromRequest(
    Map<String, dynamic> req, {
    String path = 'Workspace > Collection',
  }) {
    final rKind = req['requestKind'] ?? 'http';
    final rMethod = req['method'] ?? 'GET';
    final rUrl = req['url'] ?? '';
    final rDocs = req['docs'] ?? '';
    final rAuthType = req['authType'] ?? 'inherit';
    final rAuthConfig = Map<String, dynamic>.from(req['authConfig'] ?? {});
    final rHeaders = List<Map<String, dynamic>>.from(req['headers'] ?? []);
    final rParams = List<Map<String, dynamic>>.from(req['queryParams'] ?? []);
    final rBodyType = req['bodyType'] ?? 'none';
    final rBodyFormat = (req['bodyFormat'] ?? 'json').toString().toLowerCase();
    final rBody = req['body'] ?? '';
    final rSocketConfig = Map<String, dynamic>.from(req['socketConfig'] ?? {});

    List<Map<String, dynamic>> rSocketEvents = [];
    if (rSocketConfig['events'] is List) {
      rSocketEvents = (rSocketConfig['events'] as List)
          .map((e) => {'key': e.toString(), 'value': '', 'description': '', 'enabled': true})
          .toList();
    }

    dynamic rawBody = '';
    List<Map<String, dynamic>> rFormData = [];
    List<Map<String, dynamic>> rUrlEncoded = [];

    if (rBody is Map && rBody.containsKey('raw')) {
      rawBody = rBody['raw'] ?? '';
      if (rBody['formData'] is List) {
        rFormData = List<Map<String, dynamic>>.from(rBody['formData'].map((e) => Map<String, dynamic>.from(e)));
      }
      if (rBody['urlEncodedData'] is List) {
        rUrlEncoded = List<Map<String, dynamic>>.from(rBody['urlEncodedData'].map((e) => Map<String, dynamic>.from(e)));
      }
    } else if (rBodyType == 'form-data' && rBody is List) {
      rFormData = List<Map<String, dynamic>>.from(rBody.map((e) => Map<String, dynamic>.from(e)));
    } else if ((rBodyType == 'urlencoded' || rBodyType == 'x-www-form-urlencoded') && rBody is List) {
      rUrlEncoded = List<Map<String, dynamic>>.from(rBody.map((e) => Map<String, dynamic>.from(e)));
    } else {
      rawBody = rBody;
    }

    return RequestTabSession(
      id: req['_id'] ?? '',
      name: req['name'] ?? 'Unnamed',
      path: path,
      requestKind: rKind,
      method: rMethod,
      url: rUrl,
      docs: rDocs,
      authType: rAuthType,
      authConfig: Map<String, dynamic>.from(rAuthConfig),
      headers: List<Map<String, dynamic>>.from(rHeaders),
      queryParams: List<Map<String, dynamic>>.from(rParams),
      bodyType: rBodyType,
      bodyFormat: rBodyFormat,
      body: rawBody,
      formData: List<Map<String, dynamic>>.from(rFormData),
      urlEncodedData: List<Map<String, dynamic>>.from(rUrlEncoded),
      socketConfig: Map<String, dynamic>.from(rSocketConfig),
      socketEvents: List<Map<String, dynamic>>.from(rSocketEvents),
      originalRequestKind: rKind,
      originalMethod: rMethod,
      originalUrl: rUrl,
      originalDocs: rDocs,
      originalAuthType: rAuthType,
      originalAuthConfig: Map<String, dynamic>.from(rAuthConfig),
      originalHeaders: List<Map<String, dynamic>>.from(rHeaders),
      originalQueryParams: List<Map<String, dynamic>>.from(rParams),
      originalBodyType: rBodyType,
      originalBodyFormat: rBodyFormat,
      originalBody: rBody,
      originalFormData: List<Map<String, dynamic>>.from(rFormData),
      originalUrlEncodedData: List<Map<String, dynamic>>.from(rUrlEncoded),
      originalSocketConfig: Map<String, dynamic>.from(rSocketConfig),
      originalSocketEvents: List<Map<String, dynamic>>.from(rSocketEvents),
      hasUnsavedChanges: false,
    );
  }
}
