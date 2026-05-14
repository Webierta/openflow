import 'package:flutter/material.dart';

class OpenDialog {
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required Widget content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        iconPadding: .only(top: 30),
        titlePadding: .fromLTRB(40, 10, 30, 20),
        contentPadding: .fromLTRB(40, 20, 30, 20),
        actionsPadding: .fromLTRB(0, 40, 20, 30),
        icon: const Icon(Icons.warning_amber, size: 40, color: Colors.red),
        //icon: const Icon(Icons.task_alt, size: 40, color: Colors.red),
        title: Text(title),
        content: content,
        actions: <Widget>[
          FilledButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Confirm'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  static Future<String?> inputName({
    required BuildContext context,
    required String title,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(icon, size: 64),
        title: Text(title),
        content: TextField(controller: controller),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }
}
