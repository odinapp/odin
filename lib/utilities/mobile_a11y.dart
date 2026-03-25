import 'package:flutter/material.dart';

/// Clamps system text scale on mobile layouts to reduce overflow while still
/// respecting accessibility (up to [maxScaleFactor]).
Widget mobileClampedTextScale(BuildContext context, {required Widget child}) {
  final mq = MediaQuery.of(context);
  final clamped = mq.textScaler.clamp(
    minScaleFactor: 0.85,
    maxScaleFactor: 1.45,
  );
  return MediaQuery(
    data: mq.copyWith(textScaler: clamped),
    child: child,
  );
}

/// Minimum 48×48 touch target; [tooltip] drives the accessibility label on
/// platforms that use it.
Widget mobileToolbarIconButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget icon,
  String? tooltip,
}) {
  return IconButton(
    onPressed: onPressed,
    tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.all(12),
    ),
    icon: icon,
  );
}
