import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/home/controllers/workspace_controller.dart';
import '../modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/widgets/interactive_tooltip.dart';
import 'package:postmanclone/app/widgets/variable_hover_card.dart';

class VariableAutocomplete extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;

  const VariableAutocomplete({
    Key? key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.onChanged,
  }) : super(key: key);

  @override
  State<VariableAutocomplete> createState() => _VariableAutocompleteState();
}

class _VariableAutocompleteState extends State<VariableAutocomplete> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isInternalController = true;
      final reqController = Get.find<RequestBuilderController>();
      _controller = VariableTextEditingController(reqController);
      if (widget.initialValue != null) {
        _controller.text = widget.initialValue!;
      }
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _isInternalFocusNode = true;
      _focusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(VariableAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      if (_isInternalController) {
        _controller.dispose();
      }
      _controller = widget.controller!;
      _isInternalController = false;
    } else if (widget.controller == null && widget.initialValue != oldWidget.initialValue) {
      if (_controller.text != widget.initialValue) {
        final selection = _controller.selection;
        _controller.text = widget.initialValue ?? '';
        if (selection.isValid && selection.baseOffset <= _controller.text.length) {
          _controller.selection = selection;
        } else {
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        }
      }
    }

    if (widget.focusNode != null && widget.focusNode != _focusNode) {
      if (_isInternalFocusNode) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode!;
      _isInternalFocusNode = false;
    } else if (widget.focusNode == null && oldWidget.focusNode != null) {
      _isInternalFocusNode = true;
      _focusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawAutocomplete = RawAutocomplete<MapEntry<String, dynamic>>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;
        final selection = textEditingValue.selection;
        
        if (!selection.isValid || selection.isCollapsed == false) {
          return const Iterable<MapEntry<String, dynamic>>.empty();
        }
        
        final cursorPosition = selection.baseOffset;
        final textBeforeCursor = text.substring(0, cursorPosition);
        
        final lastOpenBracket = textBeforeCursor.lastIndexOf('{{');
        final lastCloseBracket = textBeforeCursor.lastIndexOf('}}');
        
        if (lastOpenBracket != -1 && lastOpenBracket > lastCloseBracket) {
          final query = textBeforeCursor.substring(lastOpenBracket + 2);
          
          final workspaceController = Get.find<WorkspaceController>();
          final reqController = Get.find<RequestBuilderController>();
          final reqId = reqController.currentRequestId.value ?? '';
          final variables = workspaceController.getVariablesForRequest(reqId);
          
          if (query.isEmpty) {
            return variables.entries;
          }
          
          return variables.entries.where((entry) => 
            entry.key.toLowerCase().contains(query.toLowerCase())
          );
        }
        
        return const Iterable<MapEntry<String, dynamic>>.empty();
      },
      displayStringForOption: (option) => option.key,
      fieldViewBuilder: (context, textEditingController, currentFocusNode, onFieldSubmitted) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: textEditingController,
          builder: (context, value, _) {
            InputDecoration dec = widget.decoration;
            if (value.text.length > 20) {
              dec = dec.copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                  tooltip: 'Expand Editor',
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text('Edit Value', style: TextStyle(color: Colors.white, fontSize: 16)),
                          content: SizedBox(
                            width: 600,
                            child: TextField(
                              controller: textEditingController, // Shares the same controller!
                              maxLines: 15,
                              onChanged: widget.onChanged,
                              style: const TextStyle(color: Color(0xFFCE9178), fontFamily: 'monospace', fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF2B2B2B),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: const Color(0xFFE65100).withOpacity(0.5), width: 2),
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done', style: TextStyle(color: Colors.orange)),
                            ),
                          ],
                        );
                      }
                    );
                  },
                ),
              );
            }
            return TextField(
              controller: textEditingController,
              focusNode: currentFocusNode,
              decoration: dec,
              style: widget.style,
              onChanged: widget.onChanged,
              onSubmitted: (val) => onFieldSubmitted(),
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      final text = _controller.text;
                      final selection = _controller.selection;
                      if (!selection.isValid) return;
                      
                      final cursorPosition = selection.baseOffset;
                      final textBeforeCursor = text.substring(0, cursorPosition);
                      final textAfterCursor = text.substring(cursorPosition);
                      
                      final lastOpenBracket = textBeforeCursor.lastIndexOf('{{');
                      if (lastOpenBracket != -1) {
                        final newTextBeforeCursor = textBeforeCursor.substring(0, lastOpenBracket) + '{{${option.key}}}';
                        
                        var newTextAfterCursor = textAfterCursor;
                        if (newTextAfterCursor.startsWith('}')) {
                          newTextAfterCursor = newTextAfterCursor.substring(1);
                        }
                        if (newTextAfterCursor.startsWith('}')) {
                          newTextAfterCursor = newTextAfterCursor.substring(1);
                        }
                        
                        final newText = newTextBeforeCursor + newTextAfterCursor;
                        
                        onSelected(option); // Closes overlay
                        
                        Future.microtask(() {
                          _controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: newTextBeforeCursor.length),
                          );
                          if (widget.onChanged != null) widget.onChanged!(newText);
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.data_object, size: 14, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option.key,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            option.value.toString().length > 20 
                                ? '${option.value.toString().substring(0, 20)}...' 
                                : option.value.toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final text = _controller.text;
        final regex = RegExp(r'\{\{([^}]+)\}\}');
        final matches = regex.allMatches(text);

        final bool hasVariables = matches.isNotEmpty;

        return InteractiveTooltip(
          enabled: hasVariables,
          popup: hasVariables ? Obx(() {
            final workspaceController = Get.find<WorkspaceController>();
            final reqController = Get.find<RequestBuilderController>();
            final reqId = reqController.currentRequestId.value ?? '';
            
            workspaceController.collections.isEmpty; // track for reactivity
            final variables = workspaceController.getVariableDetailsForRequest(reqId);

            final Set<String> uniqueVars = {};
            for (var match in matches) {
              uniqueVars.add(match.group(1)!);
            }

            List<Widget> widgets = [];
            for (var varName in uniqueVars) {
              final detail = variables[varName];
              widgets.add(VariableHoverCard(
                  varName: varName, detail: detail, requestId: reqId));
            }

            if (widgets.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            );
          }) : const SizedBox.shrink(),
          child: child!,
        );
      },
      child: rawAutocomplete,
    );
  }
}
