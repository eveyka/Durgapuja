import 'package:flutter/material.dart';
import '../screens/update_screen.dart';

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AppUpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: const AppUpdateScreen(isModal: true),
        ),
      ),
    );
  }
}
