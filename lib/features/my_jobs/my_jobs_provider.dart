// lib/features/my_jobs/my_jobs_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/relocation.dart';
import '../available_jobs/available_jobs_provider.dart';

class MyJobsNotifier extends AsyncNotifier<List<Relocation>> {
  @override
  Future<List<Relocation>> build() =>
      ref.watch(relocationApiProvider).fetchMyRelocations();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(relocationApiProvider).fetchMyRelocations(),
    );
  }
}

final myJobsProvider =
    AsyncNotifierProvider<MyJobsNotifier, List<Relocation>>(
  MyJobsNotifier.new,
);
