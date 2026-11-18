import 'package:flutter/material.dart';

import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../kanso/kanso_widgets.dart';

/// One quiet input dialog for the whole app.
///
/// The surface comes from the theme's `surfaceElevated` role (a neutral tone),
/// never from the saturated accent-family `floating` role. The submit action is
/// the only filled button on the surface; Cancel is a plain text button, and
/// submit stays disabled until something has been typed.
Future<String?> showKansoInputDialog({
  required BuildContext context,
  required String title,
  required String hint,
  required String actionLabel,
  String? helper,
  String? Function(String value)? validate,
}) async {
  final controller = TextEditingController();
  var value = '';
  String? errorText;
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final k = dialogContext.kanso;
        final text = Theme.of(dialogContext).textTheme;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (helper != null) ...[
                  Text(helper, style: text.bodySmall?.copyWith(color: k.textSecondary)),
                  const SizedBox(height: KansoSpace.md),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (input) => setState(() {
                    value = input;
                    errorText = validate?.call(input.trim());
                  }),
                  decoration: InputDecoration(hintText: hint, errorText: errorText),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: k.textSecondary),
                child: const Text('Cancel'),
              ),
              KansoPrimaryButton(
                label: actionLabel,
                onPressed: value.trim().isEmpty || validate?.call(value.trim()) != null
                    ? null
                    : () => Navigator.pop(context, value.trim()),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

/// The local scanner reads filesystem paths, so `content://` tree URIs cannot
/// be used here (see README). Fail early with a useful hint instead of adding
/// a folder that can never be scanned.
String? validateMusicFolderPath(String value) => value.startsWith('/')
    ? null
    : 'Enter an absolute path, e.g. /storage/emulated/0/Music';
