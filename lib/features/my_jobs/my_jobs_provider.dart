// lib/features/my_jobs/my_jobs_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/relocation.dart';
import '../available_jobs/available_jobs_provider.dart';

/// Provides the current authenticated user's ID. Overridable in tests.
final currentUserIdProvider = Provider<String>(
  (ref) => Supabase.instance.client.auth.currentUser!.id,
);

class MyJobsNotifier extends AsyncNotifier<List<Relocation>> {
  @override
  Future<List<Relocation>> build() {
    final userId = ref.watch(currentUserIdProvider);
    return ref.watch(relocationApiProvider).fetchMyRelocations(userId);
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserIdProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(relocationApiProvider).fetchMyRelocations(userId),
    );
  }
}

final myJobsProvider =
    AsyncNotifierProvider<MyJobsNotifier, List<Relocation>>(
  MyJobsNotifier.new,
);
