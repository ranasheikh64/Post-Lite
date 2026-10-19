import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/data/providers/http_headers_provider.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'table_field_autocomplete_item.dart';
import 'table_field_hover_wrapper.dart';
import 'table_field_text_editing_controller.dart';

class TableFieldAutocomplete extends StatefulWidget {
  final String title;
  final bool isKey;
  final String? headerKey;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextStyle? style;
  final InputDecoration decoration;

  const TableFieldAutocomplete({
    super.key, required this.title, required this.isKey, this.headerKey,
    required this.initialValue, required this.onChanged, this.style,
    this.decoration = const InputDecoration(),
  });

  @override
  State<TableFieldAutocomplete> createState() => _TableFieldAutocompleteState();
}

class _TableFieldAutocompleteState extends State<TableFieldAutocomplete> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TableFieldTextEditingController(text: widget.initialValue, isKey: widget.isKey);
    _focusNode = FocusNode();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(TableFieldAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      final sel = _controller.selection;
      _controller.text = widget.initialValue;
      if (sel.isValid && sel.baseOffset <= _controller.text.length) _controller.selection = sel;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Iterable<Object> _buildOptions(TextEditingValue textValue) {
    final text = textValue.text, sel = textValue.selection;
    final cursor = sel.isValid ? sel.baseOffset : text.length;
    final before = text.substring(0, cursor);
    final lastOpen = before.lastIndexOf('{{'), lastClose = before.lastIndexOf('}}');

    if (lastOpen != -1 && lastOpen > lastClose) {
      final q = before.substring(lastOpen + 2).toLowerCase();
      final ws = Get.find<WorkspaceController>();
      final reqCtrl = Get.find<RequestBuilderController>();
      final vars = ws.getVariablesForRequest(reqCtrl.currentRequestId.value ?? '');
      return vars.entries.where((e) => e.key.toLowerCase().contains(q));
    }
    if (widget.title == 'Headers') {
      if (widget.isKey) return HttpHeadersProvider.searchHeaders(text);
      if (widget.headerKey?.isNotEmpty == true) return HttpHeadersProvider.searchValues(widget.headerKey!, text);
    }
    return const [];
  }

  void _selectOption(Object opt, AutocompleteOnSelected<Object> onSel) {
    final String newText;
    if (opt is MapEntry) {
      final text = _controller.text, sel = _controller.selection;
      final cursor = sel.isValid ? sel.baseOffset : text.length;
      final before = text.substring(0, cursor);
      var after = text.substring(cursor);
      if (after.startsWith('}')) after = after.substring(1);
      if (after.startsWith('}')) after = after.substring(1);
      final lastOpen = before.lastIndexOf('{{');
      newText = '${lastOpen != -1 ? before.substring(0, lastOpen) : before}{{${opt.key}}}$after';
    } else {
      newText = opt is HeaderSuggestion ? opt.key : opt.toString();
    }
    onSel(opt);
    Future.microtask(() {
      _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
      widget.onChanged(newText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TableFieldHoverWrapper(
      controller: _controller,
      child: RawAutocomplete<Object>(
        textEditingController: _controller,
        focusNode: _focusNode,
        optionsBuilder: _buildOptions,
        displayStringForOption: (opt) => opt is HeaderSuggestion ? opt.key : (opt is MapEntry ? opt.key : opt.toString()),
        fieldViewBuilder: (ctx, ctrl, fn, _) => Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent && _scrollController.hasClients) {
              final d = e.scrollDelta.dy != 0 ? e.scrollDelta.dy : e.scrollDelta.dx;
              _scrollController.jumpTo((_scrollController.offset + d).clamp(0.0, _scrollController.position.maxScrollExtent));
            }
          },
          child: TextField(
            controller: ctrl,
            focusNode: fn,
            scrollController: _scrollController,
            scrollPhysics: const ClampingScrollPhysics(),
            style: widget.style,
            decoration: widget.decoration,
            onChanged: widget.onChanged,
          ),
        ),
        optionsViewBuilder: (ctx, onSel, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: const Color(0xFF1E2133),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF2E344E))),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (ctx, i) => TableFieldAutocompleteItem(option: options.elementAt(i), onTap: () => _selectOption(options.elementAt(i), onSel)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
