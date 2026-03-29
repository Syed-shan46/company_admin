import 'package:flutter/material.dart';

/// A utility class for displaying customizable snackbars.
/// Usage:
/// - AppSnackbar.success(context, "Operation successful");
/// - AppSnackbar.error(context, "Something went wrong");
/// - AppSnackbar.info(context, "Just so you know...");
class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? theme.colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show a success snackbar with green color
  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle,
      action: action,
    );
  }

  /// Show an error snackbar with red color
  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error,
      action: action,
    );
  }

  /// Show a warning snackbar with orange color
  static void warning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
      action: action,
    );
  }

  /// Show an info snackbar with blue color
  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info,
      action: action,
    );
  }
}
