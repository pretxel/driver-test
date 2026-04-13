// lib/shared/widgets/job_card.dart
import 'package:flutter/material.dart';
import '../../core/models/relocation.dart';
import 'status_badge.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.relocation, required this.onTap});

  final Relocation relocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${relocation.origin} → ${relocation.destination}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  StatusBadge(status: relocation.status),
                ],
              ),
              const SizedBox(height: 10),
              _LocationRow(
                icon: Icons.radio_button_checked,
                color: Colors.green,
                label: relocation.origin,
              ),
              const SizedBox(height: 4),
              _LocationRow(
                icon: Icons.location_on,
                color: Colors.red,
                label: relocation.destination,
              ),
              const SizedBox(height: 4),
              _LocationRow(
                icon: Icons.calendar_today,
                color: Colors.blue,
                label: _formatDate(relocation.date),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
