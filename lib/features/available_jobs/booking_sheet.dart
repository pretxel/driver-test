// lib/features/available_jobs/booking_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/relocation.dart';
import 'book_job_provider.dart';

/// Shows the booking bottom sheet and handles success/error.
void showBookingSheet(BuildContext context, WidgetRef ref, Relocation job) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: BookingSheetContent(relocation: job),
    ),
  );
}

class BookingSheetContent extends ConsumerWidget {
  const BookingSheetContent({super.key, required this.relocation});

  final Relocation relocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookJobProvider);
    final isLoading = bookState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${relocation.origin} → ${relocation.destination}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            icon: Icons.radio_button_checked,
            color: Colors.green,
            label: 'Origin',
            value: relocation.origin,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.location_on,
            color: Colors.red,
            label: 'Destination',
            value: relocation.destination,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.calendar_today,
            color: Colors.blue,
            label: 'Date',
            value: '${relocation.date.day.toString().padLeft(2, '0')}/'
                '${relocation.date.month.toString().padLeft(2, '0')}/'
                '${relocation.date.year}',
          ),
          if (relocation.notes != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.notes,
              color: Colors.grey,
              label: 'Notes',
              value: relocation.notes!,
            ),
          ],
          const SizedBox(height: 28),
          if (bookState.hasError)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Booking failed. Please try again.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final success = await ref
                        .read(bookJobProvider.notifier)
                        .book(relocation.id);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Relocation booked successfully!')),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'CONFIRM BOOKING',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey)),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
