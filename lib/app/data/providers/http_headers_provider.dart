class HeaderSuggestion {
  final String key;
  final String description;
  const HeaderSuggestion(this.key, this.description);
}

class HttpHeadersProvider {
  static const List<HeaderSuggestion> headers = [
    HeaderSuggestion('Authorization', 'Authentication credentials for HTTP authentication'),
    HeaderSuggestion('Content-Type', 'The MIME type of the body of the request (e.g. application/json)'),
    HeaderSuggestion('Accept', 'Media type(s) that are acceptable for the response'),
    HeaderSuggestion('Accept-Encoding', 'List of acceptable encodings (gzip, deflate, br)'),
    HeaderSuggestion('Accept-Language', 'List of acceptable human languages for response'),
    HeaderSuggestion('Accept-Charset', 'Character sets that are acceptable'),
    HeaderSuggestion('Cache-Control', 'Directives for caching mechanisms in requests and responses'),
    HeaderSuggestion('Connection', 'Control options for the current connection (e.g. keep-alive)'),
    HeaderSuggestion('Cookie', 'HTTP cookie previously sent by the server with Set-Cookie'),
    HeaderSuggestion('Content-Length', 'The length of the request body in octets (8-bit bytes)'),
    HeaderSuggestion('Content-Disposition', 'Information on how to process the response payload'),
    HeaderSuggestion('Content-Encoding', 'The type of encoding used on the data'),
    HeaderSuggestion('Content-Language', 'The natural language of the intended audience'),
    HeaderSuggestion('Origin', 'Initiating origin of the request (URI scheme, domain, and port)'),
    HeaderSuggestion('Referer', 'Address of the previous web page from which a link was followed'),
    HeaderSuggestion('User-Agent', 'The user agent string of the client software'),
    HeaderSuggestion('Host', 'Domain name of the server (and optionally port number)'),
    HeaderSuggestion('If-Match', 'Only perform action if client supplied entity matches'),
    HeaderSuggestion('If-None-Match', 'Allows 304 Not Modified to be returned if content is unchanged'),
    HeaderSuggestion('If-Modified-Since', 'Allows 304 Not Modified if unchanged since specified date'),
    HeaderSuggestion('If-Unmodified-Since', 'Only send response if entity has not been modified'),
    HeaderSuggestion('Access-Control-Allow-Origin', 'Indicates whether the response can be shared'),
    HeaderSuggestion('Access-Control-Request-Headers', 'Used when issuing a preflight request'),
    HeaderSuggestion('Access-Control-Request-Method', 'Used when issuing a preflight request'),
    HeaderSuggestion('Pragma', 'Implementation-specific directives (e.g. no-cache)'),
    HeaderSuggestion('Range', 'Request only part of an entity (e.g. bytes=0-1024)'),
    HeaderSuggestion('Upgrade', 'Ask the server to upgrade to another protocol'),
    HeaderSuggestion('X-API-Key', 'Custom header for passing an API key or access token'),
    HeaderSuggestion('X-Requested-With', 'Mainly used to identify Ajax/fetch requests'),
    HeaderSuggestion('X-Forwarded-For', 'Identifying the originating IP address of a client'),
    HeaderSuggestion('X-Forwarded-Proto', 'Identifying the protocol (HTTP or HTTPS) of the client'),
    HeaderSuggestion('X-CSRF-Token', 'Custom header used to prevent cross-site request forgery'),
    HeaderSuggestion('Bearer', 'Bearer token authorization scheme header'),
  ];

  static const Map<String, List<String>> commonValues = {
    'authorization': [
      'Bearer ',
      'Basic ',
      'Bearer {{token}}',
      'Digest ',
    ],
    'content-type': [
      'application/json',
      'application/x-www-form-urlencoded',
      'multipart/form-data',
      'text/plain',
      'text/html',
      'application/xml',
      'text/xml',
      'application/javascript',
      'application/octet-stream',
      'application/pdf',
    ],
    'accept': [
      'application/json',
      'text/plain',
      'text/html',
      'application/xml',
      '*/*',
    ],
    'cache-control': [
      'no-cache',
      'no-store',
      'max-age=0',
      'must-revalidate',
      'public',
      'private',
    ],
    'connection': [
      'keep-alive',
      'close',
    ],
    'accept-encoding': [
      'gzip, deflate, br',
      'gzip',
      'deflate',
      'br',
      '*',
    ],
    'accept-language': [
      'en-US,en;q=0.9',
      'en-GB,en;q=0.8',
      '*',
    ],
  };

  static List<HeaderSuggestion> searchHeaders(String query) {
    var clean = query.trim().toLowerCase();
    if (clean.isEmpty) return headers.take(15).toList();
    if (clean.contains('auther')) clean = clean.replaceAll('auther', 'author');
    if (clean.contains('authorz')) clean = clean.replaceAll('authorz', 'authoriz');
    return headers.where((h) =>
      h.key.toLowerCase().contains(clean) || h.description.toLowerCase().contains(clean)
    ).toList();
  }

  static List<String> searchValues(String headerKey, String query) {
    final cleanKey = headerKey.trim().toLowerCase();
    final cleanQ = query.trim().toLowerCase();
    final values = commonValues[cleanKey] ?? [];
    if (cleanQ.isEmpty) return values;
    return values.where((v) => v.toLowerCase().contains(cleanQ)).toList();
  }
}
