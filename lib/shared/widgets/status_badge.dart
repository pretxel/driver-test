// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../../core/models/relocation.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final RelocationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RelocationStatus.pending    => ('PENDING', Colors.amber),
      RelocationStatus.inProgress => ('IN PROGRESS', Colors.blue),
      RelocationStatus.completed  => ('COMPLETED', Colors.green),
      RelocationStatus.cancelled  => ('CANCELLED', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
