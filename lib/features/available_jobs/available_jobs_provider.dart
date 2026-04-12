// lib/features/available_jobs/available_jobs_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/relocation_api.dart';
import '../../core/models/relocation.dart';

final dioProvider = Provider<Dio>((ref) => createApiClient());

final relocationApiProvider = Provider<RelocationApi>(
  (ref) => RelocationApi(ref.watch(dioProvider)),
);

class AvailableJobsNotifier extends AsyncNotifier<List<Relocation>> {
  @override
  Future<List<Relocation>> build() =>
      ref.watch(relocationApiProvider).fetchPendingRelocations();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(relocationApiProvider).fetchPendingRelocations(),
    );
  }

  void removeJob(String id) {
    state.whenData((jobs) {
      state = AsyncData(jobs.where((j) => j.id != id).toList());
    });
  }
}

final availableJobsProvider =
    AsyncNotifierProvider<AvailableJobsNotifier, List<Relocation>>(
  AvailableJobsNotifier.new,
);
