import 'package:flutter/material.dart';
import '../../../../app/core/theme/app_theme.dart';
import 'unsaved_changes_dialog.dart';

class UnsavedDialogActions extends StatelessWidget {
  const UnsavedDialogActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.cancel),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.discard),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text("Don't Save"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.save),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 0,
          ),
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
