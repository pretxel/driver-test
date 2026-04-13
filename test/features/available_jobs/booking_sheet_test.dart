// test/features/available_jobs/booking_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/features/available_jobs/available_jobs_provider.dart';
import 'package:flovi_driver/features/available_jobs/booking_sheet.dart';

import 'available_jobs_provider_test.mocks.dart';

void main() {
  final sampleJob = Relocation(
    id: 'job-1',
    origin: 'Madrid',
    destination: 'Valencia',
    date: DateTime(2026, 4, 20),
    status: RelocationStatus.pending,
    createdAt: DateTime(2026, 4, 12),
  );

  testWidgets('BookingSheet shows route and CONFIRM button', (tester) async {
    final mockApi = MockRelocationApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [relocationApiProvider.overrideWithValue(mockApi)],
        child: MaterialApp(
          home: Scaffold(
            body: BookingSheetContent(relocation: sampleJob),
          ),
        ),
      ),
    );
    expect(find.text('Madrid → Valencia'), findsOneWidget);
    expect(find.text('CONFIRM BOOKING'), findsOneWidget);
  });

  testWidgets('BookingSheet calls bookRelocation on confirm tap',
      (tester) async {
    final mockApi = MockRelocationApi();
    when(mockApi.fetchPendingRelocations()).thenAnswer((_) async => []);
    when(mockApi.bookRelocation('job-1')).thenAnswer((_) async => Relocation(
          id: 'job-1',
          origin: 'Madrid',
          destination: 'Valencia',
          date: DateTime(2026, 4, 20),
          status: RelocationStatus.inProgress,
          createdAt: DateTime(2026, 4, 12),
        ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [relocationApiProvider.overrideWithValue(mockApi)],
        child: MaterialApp(
          home: Scaffold(body: BookingSheetContent(relocation: sampleJob)),
        ),
      ),
    );

    await tester.tap(find.text('CONFIRM BOOKING'));
    await tester.pump();

    verify(mockApi.bookRelocation('job-1')).called(1);
  });
}
