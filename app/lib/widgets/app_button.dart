import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized button component for consistent styling across all screens
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool isEnabled;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.isLoading = false,
    this.isEnabled = true,
  });

  /// Standard pill button matching upload screen style
  factory AppButton.pill({
    required String text,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Colors.white,
      textColor: textColor ?? AppColors.textDark,
      width: 200,
      height: 60,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// Primary button with violet background
  factory AppButton.primary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      width: 200,
      height: 60,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// Orange button for submit actions
  factory AppButton.orange({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: AppColors.orange,
      textColor: Colors.white,
      width: 200,
      height: 60,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Colors.white;
    final effectiveTextColor = textColor ?? AppColors.textDark;
    final actualWidth = width ?? 200;
    final actualHeight = height ?? 60;

    return Container(
      width: actualWidth,
      height: actualHeight,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(actualHeight / 2), // Always pill-shaped
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isEnabled && !isLoading) ? onPressed : null,
          borderRadius: BorderRadius.circular(actualHeight / 2),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                    ),
                  )
                : Text(
                    text,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: effectiveTextColor,
                      fontSize: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}