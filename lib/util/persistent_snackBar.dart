import 'package:flutter/material.dart';

class PersistentSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    required String actionTitle,
    required String navigation,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionTitle,
          onPressed: () {
            Navigator.pushNamed(context, navigation);
          },
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
}
