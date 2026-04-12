// test/shared/widgets/job_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/shared/widgets/job_card.dart';

void main() {
  final relocation = Relocation(
    id: 'test-1',
    vehicleMake: 'Ford',
    vehicleModel: 'Focus',
    pickupLocation: 'Main Depot',
    dropoffLocation: 'Airport T1',
    status: RelocationStatus.pending,
    createdAt: DateTime(2026, 4, 12),
  );

  testWidgets('JobCard displays vehicle make and model', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JobCard(relocation: relocation, onTap: () {})),
      ),
    );
    expect(find.text('Ford Focus'), findsOneWidget);
  });

  testWidgets('JobCard displays pickup and dropoff', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JobCard(relocation: relocation, onTap: () {})),
      ),
    );
    expect(find.text('Main Depot'), findsOneWidget);
    expect(find.text('Airport T1'), findsOneWidget);
  });

  testWidgets('JobCard calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobCard(relocation: relocation, onTap: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.byType(JobCard));
    expect(tapped, isTrue);
  });
}
