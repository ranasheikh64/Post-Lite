import 'package:flutter/material.dart';
import 'unsaved_auto_save_tile.dart';
import 'unsaved_dialog_actions.dart';

enum UnsavedChangesAction { save, discard, cancel }

class UnsavedChangesDialog extends StatefulWidget {
  final String requestName;
  final bool autoSaveEnabled;
  final ValueChanged<bool>? onAutoSaveToggled;

  const UnsavedChangesDialog({
    super.key,
    required this.requestName,
    this.autoSaveEnabled = false,
    this.onAutoSaveToggled,
  });

  static Future<UnsavedChangesAction?> show(
    BuildContext context,
    String requestName, {
    bool autoSaveEnabled = false,
    ValueChanged<bool>? onAutoSaveToggled,
  }) {
    return showDialog<UnsavedChangesAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnsavedChangesDialog(
        requestName: requestName,
        autoSaveEnabled: autoSaveEnabled,
        onAutoSaveToggled: onAutoSaveToggled,
      ),
    );
  }

  @override
  State<UnsavedChangesDialog> createState() => _UnsavedChangesDialogState();
}

class _UnsavedChangesDialogState extends State<UnsavedChangesDialog> {
  late bool _autoSave;

  @override
  void initState() {
    super.initState();
    _autoSave = widget.autoSaveEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF222533),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Text(
                'Do you want to save the changes you made to "${widget.requestName}"?',
                style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your changes will be lost if you don\'t save them.',
                style: TextStyle(fontSize: 12.5, color: Colors.white54),
              ),
              const SizedBox(height: 14),
              UnsavedAutoSaveTile(
                autoSave: _autoSave,
                onChanged: (val) {
                  setState(() => _autoSave = val);
                  widget.onAutoSaveToggled?.call(val);
                },
              ),
              const SizedBox(height: 18),
              const UnsavedDialogActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Unsaved Changes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
