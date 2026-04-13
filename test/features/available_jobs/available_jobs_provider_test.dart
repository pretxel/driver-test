// test/features/available_jobs/available_jobs_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flovi_driver/core/api/relocation_api.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/features/available_jobs/available_jobs_provider.dart';

@GenerateMocks([RelocationApi])
import 'available_jobs_provider_test.mocks.dart';

void main() {
  late MockRelocationApi mockApi;

  setUp(() => mockApi = MockRelocationApi());

  final sampleJob = Relocation(
    id: 'job-1',
    origin: 'Madrid',
    destination: 'Valencia',
    date: DateTime(2026, 4, 20),
    status: RelocationStatus.pending,
    createdAt: DateTime(2026, 4, 12),
  );

  test('availableJobsProvider loads pending jobs from API', () async {
    when(mockApi.fetchPendingRelocations())
        .thenAnswer((_) async => [sampleJob]);

    final container = ProviderContainer(
      overrides: [
        relocationApiProvider.overrideWithValue(mockApi),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(availableJobsProvider.future);
    expect(state, [sampleJob]);
  });

  test('availableJobsProvider exposes error on API failure', () async {
    when(mockApi.fetchPendingRelocations())
        .thenThrow(Exception('Network error'));

    final container = ProviderContainer(
      overrides: [
        relocationApiProvider.overrideWithValue(mockApi),
      ],
    );
    addTearDown(container.dispose);

    // trigger the provider
    container.read(availableJobsProvider);
    await Future.delayed(Duration.zero);
    expect(container.read(availableJobsProvider).hasError, isTrue);
  });
}
