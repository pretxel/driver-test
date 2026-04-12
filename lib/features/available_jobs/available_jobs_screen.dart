// lib/features/available_jobs/available_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/job_card.dart';
import '../auth/auth_provider.dart';
import '../my_jobs/my_jobs_screen.dart';
import 'available_jobs_provider.dart';
import 'booking_sheet.dart';

class AvailableJobsScreen extends ConsumerWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
      drawer: const _AppDrawer(),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load jobs',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(availableJobsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (jobs) => jobs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No available jobs right now'),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(availableJobsProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => JobCard(
                    relocation: jobs[i],
                    onTap: () => showBookingSheet(context, ref, jobs[i]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentSession?.user;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(
                                user!.userMetadata!['avatar_url'] as String)
                            : null,
                    child: user?.userMetadata?['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.userMetadata?['full_name'] as String? ?? 'Driver',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Available Jobs'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('My Jobs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
