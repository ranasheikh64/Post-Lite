import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';

void showCodeSnippetSidePanel(BuildContext context, RequestBuilderController controller) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Code Snippet',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 500,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C), // Postman dark sidebar color
              border: Border(left: BorderSide(color: Colors.grey[800]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(-5, 0),
                )
              ]
            ),
            child: CodeSnippetSidebar(controller: controller),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

class CodeSnippetSidebar extends StatefulWidget {
  final RequestBuilderController controller;

  const CodeSnippetSidebar({super.key, required this.controller});

  @override
  State<CodeSnippetSidebar> createState() => _CodeSnippetSidebarState();
}

class _CodeSnippetSidebarState extends State<CodeSnippetSidebar> {
  String selectedLanguage = 'cURL';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text(
                'Code snippet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                splashRadius: 20,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLanguage,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: ['cURL', 'Dart (http)', 'JavaScript (Fetch)']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedLanguage = val);
                  },
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.grey),
                onPressed: () {}, // Placeholder for settings
                splashRadius: 20,
                tooltip: 'Settings',
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generateSnippet()));
                  CustomSnackbar.show(title: 'Copied', message: 'Code copied to clipboard');
                },
                splashRadius: 20,
                tooltip: 'Copy to clipboard',
              )
            ],
          ),
        ),
        
        // Code Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _generateSnippet(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFE2B93D), // Yellowish string color often used in code themes
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _generateSnippet() {
    final c = widget.controller;
    
    // Process url
    final url = c.url.value.isEmpty ? 'http://example.com' : c.url.value;
    final method = c.method.value;

    // Build headers
    final Map<String, String> headers = {};
    for (var h in c.headers) {
      if (h['enabled'] == true && h['key'].toString().isNotEmpty) {
        headers[h['key']] = h['value'] ?? '';
      }
    }

    if (c.authType.value == 'bearer' && c.authConfig['token'] != null) {
      headers['Authorization'] = 'Bearer ${c.authConfig['token']}';
    } else if (c.authType.value == 'basic' && c.authConfig['username'] != null) {
      // Basic auth doesn't easily translate without base64, but we can do a placeholder
      headers['Authorization'] = 'Basic <base64_credentials>';
    }

    // Build body
    String? bodyData;
    if (c.bodyType.value == 'raw') {
      bodyData = c.body.value;
      if (c.bodyFormat.value == 'json') {
        headers['Content-Type'] = 'application/json';
      }
    } else if (c.bodyType.value == 'form-data') {
      bodyData = '// form-data snippet generation is not fully implemented yet.';
    } else if (c.bodyType.value == 'urlencoded') {
      bodyData = '// urlencoded snippet generation is not fully implemented yet.';
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    if (selectedLanguage == 'cURL') {
      return _generateCurl(url, method, headers, bodyData);
    } else if (selectedLanguage == 'Dart (http)') {
      return _generateDart(url, method, headers, bodyData);
    } else if (selectedLanguage == 'JavaScript (Fetch)') {
      return _generateFetch(url, method, headers, bodyData);
    }
    return '';
  }

  String _generateCurl(String url, String method, Map<String, String> headers, String? body) {
    final sb = StringBuffer();
    sb.writeln("curl --location --request $method '$url' \\");
    
    headers.forEach((key, value) {
      sb.writeln("--header '$key: $value' \\");
    });

    if (body != null && body.isNotEmpty) {
      final escapedBody = body.replaceAll("'", "'\\''");
      sb.writeln("--data-raw '$escapedBody'");
    } else {
      // Remove trailing slash if no body
      final str = sb.toString();
      if (str.endsWith(" \\\n")) {
        return str.substring(0, str.length - 3);
      }
    }

    return sb.toString().trimRight();
  }

  String _generateDart(String url, String method, Map<String, String> headers, String? body) {
    final sb = StringBuffer();
    sb.writeln("import 'package:http/http.dart' as http;");
    if (body != null && headers['Content-Type'] == 'application/json') {
      sb.writeln("import 'dart:convert';");
    }
    sb.writeln("\nvoid main() async {");
    
    sb.writeln("  var headers = {");
    headers.forEach((key, value) {
      sb.writeln("    '$key': '$value',");
    });
    sb.writeln("  };\n");
    
    sb.writeln("  var request = http.Request('$method', Uri.parse('$url'));");
    if (body != null && body.isNotEmpty) {
      final escapedBody = body.replaceAll("'", "\\'").replaceAll('\n', '\\n');
      sb.writeln("  request.body = '''$escapedBody''';");
    }
    
    sb.writeln("  request.headers.addAll(headers);\n");
    sb.writeln("  http.StreamedResponse response = await request.send();\n");
    sb.writeln("  if (response.statusCode == 200) {");
    sb.writeln("    print(await response.stream.bytesToString());");
    sb.writeln("  } else {");
    sb.writeln("    print(response.reasonPhrase);");
    sb.writeln("  }");
    sb.writeln("}");
    return sb.toString();
  }

  String _generateFetch(String url, String method, Map<String, String> headers, String? body) {
    final sb = StringBuffer();
    sb.writeln("var headers = new Headers();");
    headers.forEach((key, value) {
      sb.writeln("headers.append('$key', '$value');");
    });
    
    sb.writeln("\nvar requestOptions = {");
    sb.writeln("  method: '$method',");
    sb.writeln("  headers: headers,");
    if (body != null && body.isNotEmpty) {
      final escapedBody = body.replaceAll("`", "\\`");
      sb.writeln("  body: `$escapedBody`,");
    }
    sb.writeln("  redirect: 'follow'");
    sb.writeln("};\n");
    
    sb.writeln("fetch(\"$url\", requestOptions)");
    sb.writeln("  .then(response => response.text())");
    sb.writeln("  .then(result => console.log(result))");
    sb.writeln("  .catch(error => console.log('error', error));");
    return sb.toString();
  }
}
