import 'package:flutter/material.dart';

void showTopNotice(
  BuildContext context,
  String message, {
  IconData icon = Icons.info_outline,
  Duration duration = const Duration(milliseconds: 2400),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentMaterialBanner();
  messenger.showMaterialBanner(
    MaterialBanner(
      leading: Icon(icon),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('닫기'),
        ),
      ],
    ),
  );

  Future<void>.delayed(duration, () {
    if (context.mounted) {
      messenger.hideCurrentMaterialBanner();
    }
  });
}
