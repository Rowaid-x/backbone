import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  const StatusBadge({super.key, required this.status, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _resolve(String status) {
    switch (status) {
      case 'confirmed':
        return ('Confirmed', AppColors.statusConfirmed);
      case 'in_progress':
        return ('In Progress', AppColors.statusInProgress);
      case 'proposed':
        return ('Proposed', AppColors.statusProposed);
      case 'completed':
        return ('Completed', AppColors.statusCompleted);
      case 'cancelled':
        return ('Cancelled', AppColors.statusCancelled);
      case 'done':
        return ('Done', AppColors.statusConfirmed);
      case 'needs_attention':
        return ('Needs Attention', AppColors.error);
      case 'pending':
        return ('Pending', AppColors.statusProposed);
      case 'not_started':
        return ('Not Started', AppColors.textSecondary);
      default:
        return (status, AppColors.textSecondary);
    }
  }
}

class HealthDot extends StatelessWidget {
  final String status;
  const HealthDot({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (_, color) = StatusBadge._resolve(status);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
