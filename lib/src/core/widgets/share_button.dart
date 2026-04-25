/// Reusable share action — wraps `share_plus` with sensible defaults.
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class IsharaShareButton extends StatelessWidget {
  const IsharaShareButton({super.key, required this.text, this.subject, this.tooltip = 'Share'});
  final String text;
  final String? subject;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.share_rounded),
      onPressed: () => Share.share(text, subject: subject),
    );
  }
}
