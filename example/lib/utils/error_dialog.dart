import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diagnostic information deliberately excludes raw exception messages, which
/// can contain credentials, URLs with tokens, or personal filesystem paths.
class ErrorDialog {
  static Future<void> show(
    BuildContext context, {
    required String code,
    required String operation,
    Object? error,
    String? details,
  }) async {
    final italian = Localizations.localeOf(context).languageCode == 'it';
    final status = error is HttpException ? RegExp(r'(?:HTTP|\(|status(?:Code)?[ :=]+)\s*(\d{3})', caseSensitive: false).firstMatch(error.message)?.group(1) : null;
    final text = [
      operation,
      '${italian ? 'Codice' : 'Code'}: $code',
      if (details != null) details,
      if (error != null) '${italian ? 'Tipo di errore' : 'Error type'}: ${error.runtimeType}',
      if (status != null) 'HTTP: $status',
      'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    ].join('\n');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(italian ? 'Operazione non riuscita' : 'Operation failed'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: Text(italian ? 'Copia dettagli' : 'Copy details'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(italian ? 'Chiudi' : 'Close'),
          ),
        ],
      ),
    );
  }
}
