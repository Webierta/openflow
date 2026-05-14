import 'package:flutter/material.dart';

class SnackbarManager {
  static void show({
    required BuildContext context,
    required String msg,
    bool? error,
  }) {
    if (!context.mounted) return;
    Color? colorError = error == true
        ? Color(0xffE78388)
        : Theme.of(context).colorScheme.onSurface;
    Color? colorTexto = error == true
        ? Colors.white
        : Theme.of(context).colorScheme.surface;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackbar = SnackBar(
      content: Text(msg, style: TextStyle(color: colorTexto)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorError,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}
