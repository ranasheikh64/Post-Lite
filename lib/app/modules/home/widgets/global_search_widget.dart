import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/core/theme/app_theme.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';

class GlobalSearchWidget extends StatefulWidget {
  const GlobalSearchWidget({Key? key}) : super(key: key);

  @override
  _GlobalSearchWidgetState createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<GlobalSearchWidget> {
  final WorkspaceController workspaceController = Get.find();
  final RequestBuilderController reqBuilder = Get.find();
  
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = false;
  Map<String, dynamic> _results = {'collections': [], 'requests': []};
  
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        if (_controller.text.isNotEmpty) {
          _showOverlay();
        }
      } else {
        // Need a slight delay to allow tapping on overlay items before closing
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            _removeOverlay();
          }
        });
      }
    });
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = {'collections': [], 'requests': []};
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    if (_overlayEntry == null && _focusNode.hasFocus) {
      _showOverlay();
    }
    
    // add an overlay update to show loading
    _overlayEntry?.markNeedsBuild();

    final results = await workspaceController.search(query);
    
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 8,
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: _buildResults(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final collections = _results['collections'] as List? ?? [];
    final requests = _results['requests'] as List? ?? [];

    if (collections.isEmpty && requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text('No results found', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      children: [
        if (requests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('REQUESTS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          ...requests.map((req) {
            final method = req['method'] ?? 'GET';
            final name = req['name'] ?? 'Unnamed';
            final collectionName = req['collectionId'] is Map ? (req['collectionId']['name'] ?? '') : '';
            return ListTile(
              leading: Text(method, style: TextStyle(color: AppTheme.getMethodColor(method), fontWeight: FontWeight.bold, fontSize: 12)),
              title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: collectionName.isNotEmpty ? Text(collectionName, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
              onTap: () {
                _removeOverlay();
                _controller.clear();
                _focusNode.unfocus();
                // Load request in builder
                reqBuilder.loadRequest(req);
              },
            );
          }).toList(),
        ],
        if (collections.isNotEmpty && requests.isNotEmpty) const Divider(color: Colors.white12),
        if (collections.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('COLLECTIONS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          ...collections.map((c) {
            final name = c['name'] ?? 'Unnamed';
            return ListTile(
              leading: const Icon(Icons.folder_outlined, color: Colors.white54, size: 20),
              title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                _removeOverlay();
                _controller.clear();
                _focusNode.unfocus();
                // Expand collection in sidebar if possible or just select it
                // For now, no specific action to open a collection in the main view since it's sidebar driven.
                // We could just toggle it or show a message.
              },
            );
          }).toList(),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _focusNode.hasFocus ? const Color(0xFF1E88E5) : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(Icons.search, color: Colors.white54, size: 18),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search APIs, collections...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),

              ),

            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  _controller.clear();
                  _onSearchChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }
}
