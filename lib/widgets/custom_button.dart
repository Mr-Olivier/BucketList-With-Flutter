import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isFullWidth;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.isFullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Choose button style based on isSecondary
    final ButtonStyle style =
        isSecondary
            ? OutlinedButton.styleFrom(
              side: BorderSide(color: color ?? Theme.of(context).primaryColor),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              foregroundColor: color ?? Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            )
            : ElevatedButton.styleFrom(
              backgroundColor: color ?? Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            );

    // Create the button based on icon presence
    Widget buttonContent =
        icon != null
            ? isSecondary
                ? OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(text),
                  style: style,
                )
                : ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(text),
                  style: style,
                )
            : isSecondary
            ? OutlinedButton(
              onPressed: onPressed,
              child: Text(text),
              style: style,
            )
            : ElevatedButton(
              onPressed: onPressed,
              child: Text(text),
              style: style,
            );

    // Wrap in SizedBox if full width is required
    return isFullWidth
        ? SizedBox(width: double.infinity, child: buttonContent)
        : buttonContent;
  }
}
