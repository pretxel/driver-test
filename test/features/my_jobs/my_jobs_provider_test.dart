// test/features/my_jobs/my_jobs_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/features/available_jobs/available_jobs_provider.dart';
import 'package:flovi_driver/features/my_jobs/my_jobs_provider.dart';

import '../available_jobs/available_jobs_provider_test.mocks.dart';

void main() {
  late MockRelocationApi mockApi;

  setUp(() => mockApi = MockRelocationApi());

  final jobs = [
    Relocation(
      id: 'j1',
      origin: 'Madrid',
      destination: 'Valencia',
      date: DateTime(2026, 4, 20),
      status: RelocationStatus.inProgress,
      createdAt: DateTime(2026, 4, 12),
    ),
    Relocation(
      id: 'j2',
      origin: 'Barcelona',
      destination: 'Seville',
      date: DateTime(2026, 4, 21),
      status: RelocationStatus.completed,
      createdAt: DateTime(2026, 4, 11),
    ),
  ];

  test('myJobsProvider loads jobs from GET /relocations', () async {
    when(mockApi.fetchMyRelocations()).thenAnswer((_) async => jobs);

    final container = ProviderContainer(
      overrides: [relocationApiProvider.overrideWithValue(mockApi)],
    );
    addTearDown(container.dispose);

    final result = await container.read(myJobsProvider.future);
    expect(result, jobs);
    verify(mockApi.fetchMyRelocations()).called(1);
  });
}
