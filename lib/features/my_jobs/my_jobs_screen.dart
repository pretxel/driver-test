// lib/features/my_jobs/my_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/relocation.dart';
import '../../shared/widgets/job_card.dart';
import 'my_jobs_provider.dart';

class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Jobs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'IN PROGRESS'),
              Tab(text: 'COMPLETED'),
              Tab(text: 'CANCELLED'),
            ],
          ),
        ),
        body: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(myJobsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (jobs) => TabBarView(
            children: [
              _JobList(
                jobs: jobs
                    .where((j) => j.status == RelocationStatus.inProgress)
                    .toList(),
                emptyMessage: 'No jobs in progress',
              ),
              _JobList(
                jobs: jobs
                    .where((j) => j.status == RelocationStatus.completed)
                    .toList(),
                emptyMessage: 'No completed jobs yet',
              ),
              _JobList(
                jobs: jobs
                    .where((j) => j.status == RelocationStatus.cancelled)
                    .toList(),
                emptyMessage: 'No cancelled jobs',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobList extends ConsumerWidget {
  const _JobList({required this.jobs, required this.emptyMessage});

  final List<Relocation> jobs;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(emptyMessage),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myJobsProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (_, i) => JobCard(
          relocation: jobs[i],
          onTap: () {}, // Read-only in My Jobs
        ),
      ),
    );
  }
}
