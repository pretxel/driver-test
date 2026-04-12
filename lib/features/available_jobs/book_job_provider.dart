// lib/features/available_jobs/book_job_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'available_jobs_provider.dart';

class BookJobNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> book(String jobId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(relocationApiProvider).bookRelocation(jobId),
    );
    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }
    state = const AsyncData(null);
    ref.read(availableJobsProvider.notifier).removeJob(jobId);
    return true;
  }
}

final bookJobProvider =
    AsyncNotifierProvider<BookJobNotifier, void>(BookJobNotifier.new);
