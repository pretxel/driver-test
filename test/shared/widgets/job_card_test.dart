// test/shared/widgets/job_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/shared/widgets/job_card.dart';

void main() {
  final relocation = Relocation(
    id: 'test-1',
    origin: 'Madrid',
    destination: 'Valencia',
    date: DateTime(2026, 4, 20),
    status: RelocationStatus.pending,
    createdAt: DateTime(2026, 4, 12),
  );

  testWidgets('JobCard displays origin and destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JobCard(relocation: relocation, onTap: () {})),
      ),
    );
    expect(find.text('Madrid → Valencia'), findsOneWidget);
  });

  testWidgets('JobCard displays origin and destination in location rows',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JobCard(relocation: relocation, onTap: () {})),
      ),
    );
    expect(find.text('Madrid'), findsWidgets);
    expect(find.text('Valencia'), findsWidgets);
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
