import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(255, 252, 252, 252),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.blueAccent,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ),
  );
}
