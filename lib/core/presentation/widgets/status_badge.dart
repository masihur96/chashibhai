import 'package:flutter/material.dart';

enum BadgeVariant { success, error, warning, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;

    switch (variant) {
      case BadgeVariant.success:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;
        break;
      case BadgeVariant.error:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
      case BadgeVariant.warning:
        backgroundColor = Colors.orange.shade50;
        foregroundColor = Colors.orange.shade800;
        break;
      case BadgeVariant.info:
        backgroundColor = Colors.blue.shade50;
        foregroundColor = Colors.blue.shade800;
        break;
      case BadgeVariant.neutral:
      default:
        backgroundColor = Theme.of(context).colorScheme.surfaceVariant;
        foregroundColor = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
