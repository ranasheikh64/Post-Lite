import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';

class VariableAutocompleteTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextStyle? style;
  final int? maxLines;
  final bool expands;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  final bool isKey; // whether this is a key field or value field

  const VariableAutocompleteTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.maxLines = 1,
    this.expands = false,
    this.onChanged,
    this.initialValue,
    this.isKey = false,
  }) : super(key: key);

  @override
  _VariableAutocompleteTextFieldState createState() =>
      _VariableAutocompleteTextFieldState();
}

class _VariableAutocompleteTextFieldState
    extends State<VariableAutocompleteTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  Map<String, VariableDetail> _variables = {};
  List<MapEntry<String, VariableDetail>> _filteredVariables = [];
  String _currentSearchTerm = '';
  int _searchStartIndex = -1;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final reqController = Get.isRegistered<RequestBuilderController>() 
          ? Get.find<RequestBuilderController>() 
          : null;
      if (reqController != null) {
        _controller = VariableTextEditingController(reqController)..text = widget.initialValue ?? '';
      } else {
        _controller = TextEditingController(text: widget.initialValue);
      }
    }
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }
  
  @override
  void didUpdateWidget(covariant VariableAutocompleteTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && 
        widget.controller == null && 
        _controller.text != widget.initialValue) {
      // Only update if it's not currently focused to prevent cursor jumping
      if (!_focusNode.hasFocus) {
        _controller.text = widget.initialValue!;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else {
      _onTextChanged();
    }
  }

  void _onTextChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
    
    if (!_focusNode.hasFocus) return;

    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.start != selection.end) {
      _removeOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;
    if (cursorPosition < 2) {
      _removeOverlay();
      return;
    }

    // Check if we are inside a {{...}} block
    // Look backwards for {{
    int openBraceIndex = -1;
    for (int i = cursorPosition - 1; i > 0; i--) {
      if (text[i] == '{' && text[i - 1] == '{') {
        openBraceIndex = i - 1;
        break;
      }
      // If we hit a closing brace or space before finding an opening brace, we abort
      if (text[i] == '}' || text[i] == ' ') {
        break;
      }
    }

    if (openBraceIndex != -1) {
      // Check if it's already closed before the cursor
      bool isClosed = false;
      for (int i = openBraceIndex + 2; i < cursorPosition; i++) {
        if (i + 1 < text.length && text[i] == '}' && text[i + 1] == '}') {
          isClosed = true;
          break;
        }
      }

      if (!isClosed) {
        _searchStartIndex = openBraceIndex + 2;
        _currentSearchTerm = text.substring(_searchStartIndex, cursorPosition);
        _showOverlay();
        return;
      }
    }

    _removeOverlay();
  }

  void _showOverlay() {
    if (!mounted) return;

    final requestController = Get.isRegistered<RequestBuilderController>() 
        ? Get.find<RequestBuilderController>() 
        : null;
        
    if (requestController == null) return;
    
    _variables = requestController.getAvailableVariablesMap();
    
    _filteredVariables = _variables.entries
        .where((entry) => entry.key.toLowerCase().contains(_currentSearchTerm.toLowerCase()))
        .toList();

    if (_filteredVariables.isEmpty) {
      _removeOverlay();
      return;
    }

    // Reset selected index if it's out of bounds
    if (_selectedIndex >= _filteredVariables.length) {
      _selectedIndex = 0;
    }

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertVariable(String variable) {
    final text = _controller.text;
    final cursorPosition = _searchStartIndex + _currentSearchTerm.length;
    
    // Check if there are closing braces right after
    bool hasClosingBraces = false;
    if (cursorPosition + 1 < text.length && 
        text[cursorPosition] == '}' && 
        text[cursorPosition + 1] == '}') {
      hasClosingBraces = true;
    }

    final prefix = text.substring(0, _searchStartIndex);
    final suffix = hasClosingBraces 
        ? text.substring(cursorPosition + 2) 
        : text.substring(cursorPosition);
        
    final newText = '$prefix$variable}}$suffix';
    final newCursorPosition = _searchStartIndex + variable.length + 2;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
    
    if (widget.onChanged != null) {
      widget.onChanged!(newText);
    }
    
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 250,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF2B2B2B),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredVariables.length,
                  itemBuilder: (context, index) {
                    final variableEntry = _filteredVariables[index];
                    final variable = variableEntry.key;
                    final variableDetail = variableEntry.value;
                    final isSelected = index == _selectedIndex;
                    
                    return Listener(
                      onPointerDown: (_) {
                        _insertVariable(variable);
                      },
                      child: InkWell(
                        onTap: () {}, // Handled by Listener to prevent focus loss issues
                        onHover: (hovering) {
                        if (hovering) {
                          setState(() {
                            _selectedIndex = index;
                            _overlayEntry?.markNeedsBuild();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        color: isSelected 
                            ? const Color(0xFFE65100).withOpacity(0.2) 
                            : Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(Icons.data_object, size: 14, color: Color(0xFFE65100)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    variable,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    variableDetail.value.isNotEmpty ? variableDetail.value : 'No value',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                variableDetail.sourceName.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: (node, event) {
          if (_overlayEntry != null && event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                _selectedIndex = (_selectedIndex + 1) % _filteredVariables.length;
                _overlayEntry?.markNeedsBuild();
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _selectedIndex = (_selectedIndex - 1 + _filteredVariables.length) % _filteredVariables.length;
                _overlayEntry?.markNeedsBuild();
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter || 
                       event.logicalKey == LogicalKeyboardKey.tab) {
              _insertVariable(_filteredVariables[_selectedIndex].key);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _removeOverlay();
              return KeyEventResult.handled;
            }
          }
          
          // Original Comment shortcut logic for Body Editor
          if (widget.expands && 
              event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.slash &&
              (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
               HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
               HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
               HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight))) {
            
            final text = _controller.text;
            final selection = _controller.selection;
            
            if (!selection.isValid) return KeyEventResult.ignored;

            int start = selection.start;
            int end = selection.end;
            
            int lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
            int lineEnd = text.indexOf('\n', end);
            if (lineEnd == -1) lineEnd = text.length;

            final selectedLines = text.substring(lineStart, lineEnd).split('\n');
            bool allCommented = selectedLines.every((line) => line.trimLeft().startsWith('//'));

            String newText = '';
            for (int i = 0; i < selectedLines.length; i++) {
              String line = selectedLines[i];
              if (allCommented) {
                newText += line.replaceFirst(RegExp(r'^\s*//\s?'), '');
              } else {
                newText += '// $line';
              }
              if (i < selectedLines.length - 1) newText += '\n';
            }

            final newFullText = text.replaceRange(lineStart, lineEnd, newText);
            _controller.value = TextEditingValue(
              text: newFullText,
              selection: TextSelection(
                baseOffset: lineStart,
                extentOffset: lineStart + newText.length,
              ),
            );
            
            if (widget.onChanged != null) {
              widget.onChanged!(newFullText);
            }
            
            return KeyEventResult.handled;
          }
          
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: widget.decoration,
          style: widget.style,
          maxLines: widget.maxLines,
          expands: widget.expands,
        ),
      ),
    );
  }
}
