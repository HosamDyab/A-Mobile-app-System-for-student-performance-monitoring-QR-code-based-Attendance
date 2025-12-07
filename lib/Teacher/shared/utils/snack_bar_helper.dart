import 'package:flutter/material.dart';
import '../constants/app_color.dart';

/// Shows a success snackbar with green background
/// 
/// [context] - BuildContext to show the snackbar
/// [message] - Message to display
/// [duration] - How long to show the snackbar (default: 3 seconds)
/// [action] - Optional action button
void showSuccessSnackBar(
  BuildContext context,
  String message, {
  Duration? duration,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Shows an error snackbar with red background
/// 
/// [context] - BuildContext to show the snackbar
/// [message] - Message to display
/// [duration] - How long to show the snackbar (default: 4 seconds for errors)
/// [action] - Optional action button
void showErrorSnackBar(
  BuildContext context,
  String message, {
  Duration? duration,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Shows a warning snackbar with amber background
/// 
/// [context] - BuildContext to show the snackbar
/// [message] - Message to display
/// [duration] - How long to show the snackbar (default: 3 seconds)
/// [action] - Optional action button
void showWarningSnackBar(
  BuildContext context,
  String message, {
  Duration? duration,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.warning,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Shows an info snackbar with primary color background
/// 
/// [context] - BuildContext to show the snackbar
/// [message] - Message to display
/// [duration] - How long to show the snackbar (default: 3 seconds)
/// [action] - Optional action button
void showInfoSnackBar(
  BuildContext context,
  String message, {
  Duration? duration,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
      margin: const EdgeInsets.all(16),
    ),
  );
}