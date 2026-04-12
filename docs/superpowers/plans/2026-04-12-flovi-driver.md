# Flovi Driver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter 3 driver mobile app for vehicle relocation management with Google authentication, browsing/booking pending jobs, and tracking booked jobs.

**Architecture:** Feature-first folder structure with Riverpod 2 for state management and go_router for navigation (side drawer). A Dio HTTP client with a Supabase JWT interceptor handles all API calls. Each feature is self-contained with its own screens and providers.

**Tech Stack:** Flutter 3, Dart, supabase_flutter ^2.5.6, google_sign_in ^6.2.1, flutter_riverpod ^2.5.1, riverpod_annotation ^2.3.5, go_router ^14.2.0, dio ^5.4.3, mockito ^5.4.4, build_runner ^2.4.9

---

## File Map

```
flovi_driver/
├── pubspec.yaml
├── lib/
│   ├── main.dart                                    # App entry, ProviderScope, router
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart                      # Dio instance + JWT interceptor
│   │   │   └── relocation_api.dart                  # API method calls
│   │   ├── auth/
│   │   │   └── auth_service.dart                    # Supabase + Google Sign-In wrapper
│   │   ├── models/
│   │   │   └── relocation.dart                      # Relocation class + RelocationStatus enum
│   │   └── router/
│   │       └── app_router.dart                      # go_router config + redirect guard
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_provider.dart                   # authStateProvider (StreamProvider)
│   │   │   └── login_screen.dart                    # Login screen UI
│   │   ├── available_jobs/
│   │   │   ├── available_jobs_provider.dart          # AsyncNotifierProvider for pending list
│   │   │   ├── available_jobs_screen.dart            # Browse pending relocations UI
│   │   │   ├── book_job_provider.dart                # AsyncNotifierProvider for booking
│   │   │   └── booking_sheet.dart                   # Bottom sheet confirmation UI
│   │   └── my_jobs/
│   │       ├── my_jobs_provider.dart                 # AsyncNotifierProvider for booked jobs
│   │       └── my_jobs_screen.dart                  # Tabbed IN_PROGRESS/COMPLETED/CANCELLED UI
│   └── shared/
│       └── widgets/
│           ├── job_card.dart                        # Reusable job card widget
│           └── status_badge.dart                    # Color-coded status chip
├── test/
│   ├── core/models/
│   │   └── relocation_test.dart
│   ├── features/
│   │   ├── available_jobs/
│   │   │   ├── available_jobs_provider_test.dart
│   │   │   └── booking_sheet_test.dart
│   │   └── my_jobs/
│   │       └── my_jobs_provider_test.dart
│   └── shared/widgets/
│       └── job_card_test.dart
├── PROMPTS_LOG.md
└── README.md
```

---

## Task 1: Scaffold Flutter project and configure pubspec.yaml

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`

- [ ] **Step 1: Create the Flutter project**

```bash
flutter create flovi_driver --org com.flovi --platforms android
cd flovi_driver
```

- [ ] **Step 2: Replace pubspec.yaml with the required dependencies**

Replace the `dependencies` and `dev_dependencies` sections in `pubspec.yaml`:

```yaml
name: flovi_driver
description: Flovi Driver — vehicle relocation management app
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.6
  google_sign_in: ^6.2.1
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.0
  dio: ^5.4.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  mockito: ^5.4.4

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Install dependencies**

```bash
flutter pub get
```

Expected: All packages resolved, no version conflicts.

- [ ] **Step 4: Create placeholder main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Flovi Driver')))));
}
```

- [ ] **Step 5: Verify project builds**

```bash
flutter build apk --debug
```

Expected: Build succeeds (APK in `build/app/outputs/flutter-apk/app-debug.apk`).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore: scaffold Flutter project with dependencies"
```

---

## Task 2: Relocation model with JSON parsing

**Files:**
- Create: `lib/core/models/relocation.dart`
- Create: `test/core/models/relocation_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/relocation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flovi_driver/core/models/relocation.dart';

void main() {
  group('Relocation', () {
    final json = {
      'id': 'abc-123',
      'vehicle_make': 'Ford',
      'vehicle_model': 'Focus',
      'pickup_location': 'Main Depot',
      'dropoff_location': 'Airport T1',
      'status': 'PENDING',
      'created_at': '2026-04-12T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final r = Relocation.fromJson(json);
      expect(r.id, 'abc-123');
      expect(r.vehicleMake, 'Ford');
      expect(r.vehicleModel, 'Focus');
      expect(r.pickupLocation, 'Main Depot');
      expect(r.dropoffLocation, 'Airport T1');
      expect(r.status, RelocationStatus.pending);
      expect(r.createdAt, DateTime.parse('2026-04-12T10:00:00.000Z'));
    });

    test('fromJson maps IN_PROGRESS status', () {
      final r = Relocation.fromJson({...json, 'status': 'IN_PROGRESS'});
      expect(r.status, RelocationStatus.inProgress);
    });

    test('fromJson maps COMPLETED status', () {
      final r = Relocation.fromJson({...json, 'status': 'COMPLETED'});
      expect(r.status, RelocationStatus.completed);
    });

    test('fromJson maps CANCELLED status', () {
      final r = Relocation.fromJson({...json, 'status': 'CANCELLED'});
      expect(r.status, RelocationStatus.cancelled);
    });

    test('fromJson throws on unknown status', () {
      expect(
        () => Relocation.fromJson({...json, 'status': 'UNKNOWN'}),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/core/models/relocation_test.dart
```

Expected: FAIL — `relocation.dart` not found.

- [ ] **Step 3: Implement the Relocation model**

```dart
// lib/core/models/relocation.dart
enum RelocationStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  static RelocationStatus fromString(String value) {
    return switch (value) {
      'PENDING'     => RelocationStatus.pending,
      'IN_PROGRESS' => RelocationStatus.inProgress,
      'COMPLETED'   => RelocationStatus.completed,
      'CANCELLED'   => RelocationStatus.cancelled,
      _             => throw ArgumentError('Unknown status: $value'),
    };
  }
}

class Relocation {
  const Relocation({
    required this.id,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String vehicleMake;
  final String vehicleModel;
  final String pickupLocation;
  final String dropoffLocation;
  final RelocationStatus status;
  final DateTime createdAt;

  factory Relocation.fromJson(Map<String, dynamic> json) {
    return Relocation(
      id: json['id'] as String,
      vehicleMake: json['vehicle_make'] as String,
      vehicleModel: json['vehicle_model'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropoffLocation: json['dropoff_location'] as String,
      status: RelocationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/core/models/relocation_test.dart
```

Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/relocation.dart test/core/models/relocation_test.dart
git commit -m "feat: add Relocation model with JSON parsing and status enum"
```

---

## Task 3: API client with Supabase JWT interceptor

**Files:**
- Create: `lib/core/api/api_client.dart`
- Create: `lib/core/api/relocation_api.dart`

- [ ] **Step 1: Initialize Supabase in the project**

Add the Supabase project URL and anon key. These come from your Supabase dashboard (Settings → API).

Create `lib/core/supabase_config.dart`:

```dart
// lib/core/supabase_config.dart
const supabaseUrl = 'https://vfmtrozkajbwaxdgdmys.supabase.co';
// Replace with your actual anon key from Supabase Dashboard → Settings → API
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

- [ ] **Step 2: Create the Dio API client with JWT interceptor**

```dart
// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _baseUrl =
    'https://vfmtrozkajbwaxdgdmys.supabase.co/functions/v1/api';

Dio createApiClient() {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      handler.next(options);
    },
  ));

  return dio;
}
```

- [ ] **Step 3: Create the RelocationApi service**

```dart
// lib/core/api/relocation_api.dart
import 'package:dio/dio.dart';
import '../models/relocation.dart';

class RelocationApi {
  RelocationApi(this._dio);

  final Dio _dio;

  /// POST /api/v1/relocations — returns PENDING relocations available to book
  Future<List<Relocation>> fetchPendingRelocations() async {
    final response = await _dio.post<List<dynamic>>('/api/v1/relocations');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Relocation.fromJson)
        .toList();
  }

  /// GET /api/v1/relocations — returns driver's own jobs (non-pending)
  Future<List<Relocation>> fetchMyRelocations() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/relocations');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Relocation.fromJson)
        .toList();
  }

  /// PUT /api/v1/relocations/{id} — books a relocation (PENDING → IN_PROGRESS)
  Future<Relocation> bookRelocation(String id) async {
    final response =
        await _dio.put<Map<String, dynamic>>('/api/v1/relocations/$id');
    return Relocation.fromJson(response.data!);
  }
}
```

- [ ] **Step 4: Verify compilation**

```bash
flutter analyze lib/core/
```

Expected: No errors or warnings.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/ lib/core/supabase_config.dart
git commit -m "feat: add Dio API client with Supabase JWT interceptor and RelocationApi"
```

---

## Task 4: Auth service + Supabase initialization

**Files:**
- Create: `lib/core/auth/auth_service.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create the auth service**

```dart
// lib/core/auth/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  /// Signs the user in with Google and creates a Supabase session.
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Google idToken is null');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  /// Signs the user out from both Google and Supabase.
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _client.auth.signOut(),
    ]);
  }
}
```

- [ ] **Step 2: Initialize Supabase in main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ProviderScope(child: _App()));
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Flovi Driver'))),
    );
  }
}
```

- [ ] **Step 3: Configure Google Sign-In on Android**

In `android/app/build.gradle`, confirm `minSdkVersion` is at least 21:

```groovy
android {
    defaultConfig {
        minSdkVersion 21
        // ...
    }
}
```

- [ ] **Step 4: Verify compilation**

```bash
flutter analyze lib/
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/auth_service.dart lib/main.dart android/app/build.gradle
git commit -m "feat: add AuthService with Google Sign-In and Supabase initialization"
```

---

## Task 5: go_router with auth redirect guard

**Files:**
- Create: `lib/core/router/app_router.dart`
- Create: `lib/features/auth/auth_provider.dart`

- [ ] **Step 1: Create the authStateProvider**

```dart
// lib/features/auth/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Streams Supabase auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
```

- [ ] **Step 2: Create the app router with redirect guard**

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/available_jobs/available_jobs_screen.dart';
import '../../features/my_jobs/my_jobs_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/available-jobs',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null ||
          Supabase.instance.client.auth.currentSession != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/available-jobs';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/available-jobs',
        builder: (context, state) => const AvailableJobsScreen(),
      ),
      GoRoute(
        path: '/my-jobs',
        builder: (context, state) => const MyJobsScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 3: Create placeholder screens so the router compiles**

```dart
// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Login')));
}
```

```dart
// lib/features/available_jobs/available_jobs_screen.dart
import 'package:flutter/material.dart';
class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Available Jobs')));
}
```

```dart
// lib/features/my_jobs/my_jobs_screen.dart
import 'package:flutter/material.dart';
class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('My Jobs')));
}
```

- [ ] **Step 4: Wire the router into main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ProviderScope(child: _App()));
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Flovi Driver',
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2196F3),
        secondary: Color(0xFF64B5F6),
        surface: Color(0xFF1B2C3E),
        onSurface: Color(0xFFE0E8F0),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      cardColor: const Color(0xFF1B2C3E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B2C3E),
        foregroundColor: Color(0xFFE0E8F0),
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0D1B2A),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify compilation**

```bash
flutter analyze lib/
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/auth_provider.dart lib/core/router/app_router.dart \
  lib/features/auth/login_screen.dart lib/features/available_jobs/available_jobs_screen.dart \
  lib/features/my_jobs/my_jobs_screen.dart lib/main.dart
git commit -m "feat: add go_router with auth redirect guard and dark navy theme"
```

---

## Task 6: Login screen

**Files:**
- Modify: `lib/features/auth/login_screen.dart`

- [ ] **Step 1: Implement the full login screen**

```dart
// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo / brand
              Center(
                child: Column(
                  children: [
                    Icon(Icons.directions_car_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Flovi Driver',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vehicle relocation made easy',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Sign in button
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      key: const Key('google_sign_in_button'),
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/features/auth/
```

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/login_screen.dart
git commit -m "feat: implement Google sign-in login screen"
```

---

## Task 7: JobCard and StatusBadge shared widgets (TDD)

**Files:**
- Create: `lib/shared/widgets/status_badge.dart`
- Create: `lib/shared/widgets/job_card.dart`
- Create: `test/shared/widgets/job_card_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/shared/widgets/job_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/shared/widgets/job_card.dart';

void main() {
  final relocation = Relocation(
    id: 'test-1',
    vehicleMake: 'Ford',
    vehicleModel: 'Focus',
    pickupLocation: 'Main Depot',
    dropoffLocation: 'Airport T1',
    status: RelocationStatus.pending,
    createdAt: DateTime(2026, 4, 12),
  );

  testWidgets('JobCard displays vehicle make and model', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JobCard(relocation: relocation, onTap: () {})),
      ),
    );
    expect(find.text('Ford Focus'), findsOneWidget);
  });

  testWidgets('JobCard displays pickup and dropoff', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JobCard(relocation: relocation, onTap: () {})),
      ),
    );
    expect(find.text('Main Depot'), findsOneWidget);
    expect(find.text('Airport T1'), findsOneWidget);
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
```

- [ ] **Step 2: Run test to confirm failure**

```bash
flutter test test/shared/widgets/job_card_test.dart
```

Expected: FAIL — `job_card.dart` not found.

- [ ] **Step 3: Create StatusBadge widget**

```dart
// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../../core/models/relocation.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final RelocationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RelocationStatus.pending    => ('PENDING', Colors.amber),
      RelocationStatus.inProgress => ('IN PROGRESS', Colors.blue),
      RelocationStatus.completed  => ('COMPLETED', Colors.green),
      RelocationStatus.cancelled  => ('CANCELLED', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create JobCard widget**

```dart
// lib/shared/widgets/job_card.dart
import 'package:flutter/material.dart';
import '../../core/models/relocation.dart';
import 'status_badge.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.relocation, required this.onTap});

  final Relocation relocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${relocation.vehicleMake} ${relocation.vehicleModel}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  StatusBadge(status: relocation.status),
                ],
              ),
              const SizedBox(height: 10),
              _LocationRow(
                icon: Icons.radio_button_checked,
                color: Colors.green,
                label: relocation.pickupLocation,
              ),
              const SizedBox(height: 4),
              _LocationRow(
                icon: Icons.location_on,
                color: Colors.red,
                label: relocation.dropoffLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run tests to confirm they pass**

```bash
flutter test test/shared/widgets/job_card_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/ test/shared/widgets/
git commit -m "feat: add JobCard and StatusBadge widgets with tests"
```

---

## Task 8: AvailableJobsProvider with tests

**Files:**
- Create: `lib/features/available_jobs/available_jobs_provider.dart`
- Create: `test/features/available_jobs/available_jobs_provider_test.dart`

- [ ] **Step 1: Write the failing provider test**

```dart
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
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    pickupLocation: 'Depot A',
    dropoffLocation: 'Station B',
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

    final state = container.read(availableJobsProvider);
    await Future.delayed(Duration.zero);
    expect(container.read(availableJobsProvider).hasError, isTrue);
  });
}
```

- [ ] **Step 2: Run test to confirm failure**

```bash
flutter test test/features/available_jobs/available_jobs_provider_test.dart
```

Expected: FAIL — provider not defined.

- [ ] **Step 3: Generate mocks**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `available_jobs_provider_test.mocks.dart` generated.

- [ ] **Step 4: Create the AvailableJobsProvider**

```dart
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
```

- [ ] **Step 5: Run tests to confirm they pass**

```bash
flutter test test/features/available_jobs/available_jobs_provider_test.dart
```

Expected: Both tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/available_jobs/available_jobs_provider.dart \
  test/features/available_jobs/
git commit -m "feat: add AvailableJobsProvider with API integration and tests"
```

---

## Task 9: AvailableJobsScreen with full UI

**Files:**
- Modify: `lib/features/available_jobs/available_jobs_screen.dart`

- [ ] **Step 1: Implement the full AvailableJobsScreen**

```dart
// lib/features/available_jobs/available_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/job_card.dart';
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
              Text('Failed to load jobs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(availableJobsProvider.notifier).refresh(),
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
                onRefresh: () => ref.read(availableJobsProvider.notifier).refresh(),
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
                    backgroundImage: user?.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
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
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
```

> **Note:** Import `authServiceProvider` from `'../auth/auth_provider.dart'` at the top of this file.

- [ ] **Step 2: Verify compilation**

```bash
flutter analyze lib/features/available_jobs/available_jobs_screen.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/available_jobs/available_jobs_screen.dart
git commit -m "feat: implement AvailableJobsScreen with drawer, empty/error states"
```

---

## Task 10: BookJobProvider and BookingSheet (TDD)

**Files:**
- Create: `lib/features/available_jobs/book_job_provider.dart`
- Create: `lib/features/available_jobs/booking_sheet.dart`
- Create: `test/features/available_jobs/booking_sheet_test.dart`

- [ ] **Step 1: Write the failing booking sheet test**

```dart
// test/features/available_jobs/booking_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flovi_driver/core/api/relocation_api.dart';
import 'package:flovi_driver/core/models/relocation.dart';
import 'package:flovi_driver/features/available_jobs/available_jobs_provider.dart';
import 'package:flovi_driver/features/available_jobs/booking_sheet.dart';

import 'available_jobs_provider_test.mocks.dart';

void main() {
  final sampleJob = Relocation(
    id: 'job-1',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    pickupLocation: 'Depot A',
    dropoffLocation: 'Station B',
    status: RelocationStatus.pending,
    createdAt: DateTime(2026, 4, 12),
  );

  testWidgets('BookingSheet shows vehicle name and CONFIRM button', (tester) async {
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
    expect(find.text('Toyota Camry'), findsOneWidget);
    expect(find.text('CONFIRM BOOKING'), findsOneWidget);
  });

  testWidgets('BookingSheet calls bookRelocation on confirm tap', (tester) async {
    final mockApi = MockRelocationApi();
    when(mockApi.fetchPendingRelocations()).thenAnswer((_) async => []);
    when(mockApi.bookRelocation('job-1')).thenAnswer((_) async => Relocation(
          id: 'job-1',
          vehicleMake: 'Toyota',
          vehicleModel: 'Camry',
          pickupLocation: 'Depot A',
          dropoffLocation: 'Station B',
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
```

- [ ] **Step 2: Run test to confirm failure**

```bash
flutter test test/features/available_jobs/booking_sheet_test.dart
```

Expected: FAIL — `booking_sheet.dart` not found.

- [ ] **Step 3: Create BookJobProvider**

```dart
// lib/features/available_jobs/book_job_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/relocation.dart';
import 'available_jobs_provider.dart';

class BookJobNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

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
```

- [ ] **Step 4: Create BookingSheet**

```dart
// lib/features/available_jobs/booking_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/relocation.dart';
import 'book_job_provider.dart';

/// Shows the booking bottom sheet and handles success/error.
void showBookingSheet(BuildContext context, WidgetRef ref, Relocation job) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: BookingSheetContent(relocation: job),
    ),
  );
}

class BookingSheetContent extends ConsumerWidget {
  const BookingSheetContent({super.key, required this.relocation});

  final Relocation relocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookJobProvider);
    final isLoading = bookState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${relocation.vehicleMake} ${relocation.vehicleModel}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            icon: Icons.radio_button_checked,
            color: Colors.green,
            label: 'Pick up',
            value: relocation.pickupLocation,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.location_on,
            color: Colors.red,
            label: 'Drop off',
            value: relocation.dropoffLocation,
          ),
          const SizedBox(height: 28),
          if (bookState.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Booking failed. Please try again.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final success = await ref
                        .read(bookJobProvider.notifier)
                        .book(relocation.id);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Job booked successfully!')),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'CONFIRM BOOKING',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey)),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run tests to confirm they pass**

```bash
flutter test test/features/available_jobs/booking_sheet_test.dart
```

Expected: Both tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/available_jobs/book_job_provider.dart \
  lib/features/available_jobs/booking_sheet.dart \
  test/features/available_jobs/booking_sheet_test.dart
git commit -m "feat: add BookJobProvider and BookingSheet with confirmation flow"
```

---

## Task 11: MyJobsProvider and MyJobsScreen (TDD)

**Files:**
- Create: `lib/features/my_jobs/my_jobs_provider.dart`
- Modify: `lib/features/my_jobs/my_jobs_screen.dart`
- Create: `test/features/my_jobs/my_jobs_provider_test.dart`

- [ ] **Step 1: Write the failing provider test**

```dart
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
      id: 'j1', vehicleMake: 'Ford', vehicleModel: 'Focus',
      pickupLocation: 'A', dropoffLocation: 'B',
      status: RelocationStatus.inProgress,
      createdAt: DateTime(2026, 4, 12),
    ),
    Relocation(
      id: 'j2', vehicleMake: 'Honda', vehicleModel: 'Civic',
      pickupLocation: 'C', dropoffLocation: 'D',
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
```

- [ ] **Step 2: Run test to confirm failure**

```bash
flutter test test/features/my_jobs/my_jobs_provider_test.dart
```

Expected: FAIL — `my_jobs_provider.dart` not found.

- [ ] **Step 3: Create MyJobsProvider**

```dart
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
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
flutter test test/features/my_jobs/my_jobs_provider_test.dart
```

Expected: PASS.

- [ ] **Step 5: Implement the full MyJobsScreen**

```dart
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
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/my_jobs/ test/features/my_jobs/
git commit -m "feat: add MyJobsProvider and MyJobsScreen with tabbed status view"
```

---

## Task 12: PROMPTS_LOG.md

**Files:**
- Create: `PROMPTS_LOG.md`

- [ ] **Step 1: Create the prompts log**

```markdown
# PROMPTS_LOG.md — Flovi Driver App

A chronological log of every agent action, teammate prompt, and key decision made during the creation of this app.

---

## Session: 2026-04-12

### Brainstorming Phase
- **User:** Provided DEFINITION.md with app requirements
- **Claude:** Explored project context (empty repo + DEFINITION.md)
- **Decision:** Side Drawer navigation (vs Bottom Nav / Home-First Stack)
- **Decision:** Dark Navy + Blue theme
- **Decision:** Feature-First architecture with Riverpod 2 + go_router

### Design Spec
- **Claude:** Presented 3-section design (Architecture, Data/API, Screens/Testing)
- **User:** Approved all sections
- **Output:** `docs/superpowers/specs/2026-04-12-flovi-driver-design.md`

### Implementation Plan
- **Claude:** Wrote full 15-task TDD implementation plan
- **Output:** `docs/superpowers/plans/2026-04-12-flovi-driver.md`

---

## Teammate Prompts

### auth-agent
> Implement Task 1–6 of the Flovi Driver implementation plan:
> Flutter project scaffold, Relocation model, API client with Supabase JWT interceptor,
> AuthService with Google Sign-In, go_router with redirect guard, and Login screen.
> Follow the plan exactly at `docs/superpowers/plans/2026-04-12-flovi-driver.md`.
> Tech: Flutter 3, supabase_flutter, google_sign_in, flutter_riverpod, go_router.

### jobs-agent
> Implement Tasks 7–9 of the Flovi Driver plan:
> JobCard + StatusBadge widgets (with tests), AvailableJobsProvider (with tests),
> and AvailableJobsScreen with side drawer, pull-to-refresh, empty/error states.
> Follow `docs/superpowers/plans/2026-04-12-flovi-driver.md`.
> The model and API client will already exist from auth-agent's work.

### booking-agent
> Implement Task 10 of the Flovi Driver plan:
> BookJobProvider and BookingSheet bottom sheet with confirmation flow, loading state,
> error snackbar, and state rollback on failure.
> Follow `docs/superpowers/plans/2026-04-12-flovi-driver.md`.

### my-jobs-agent
> Implement Task 11 of the Flovi Driver plan:
> MyJobsProvider (with tests) and MyJobsScreen with 3-tab view
> (IN_PROGRESS / COMPLETED / CANCELLED), pull-to-refresh, empty/error states.
> Follow `docs/superpowers/plans/2026-04-12-flovi-driver.md`.

### testing-agent
> Run the full test suite for the Flovi Driver app.
> Execute: flutter test --coverage
> Report: total tests, passed/failed counts, coverage percentage.
> If any tests fail, output the test name, expected vs actual, and the relevant source file.
> Agent definition: `.claude/agents/testing-agent.md`
```

- [ ] **Step 2: Commit**

```bash
git add PROMPTS_LOG.md
git commit -m "docs: add PROMPTS_LOG with teammate prompts and session decisions"
```

---

## Task 13: README with Android build instructions

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create the README**

```markdown
# Flovi Driver

Flutter 3 mobile app for vehicle relocation drivers. Browse pending relocations,
book a job with one tap, and track your booked jobs.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | 3.x | https://docs.flutter.dev/get-started/install |
| Dart | ≥ 3.3.0 | Bundled with Flutter |
| Android Studio | Ladybug+ | https://developer.android.com/studio |
| Java JDK | 17 | `brew install openjdk@17` (macOS) |
| Android SDK | API 21+ | Via Android Studio SDK Manager |

Verify your setup:
```bash
flutter doctor
```
All checks should pass (Android toolchain required).

## Setup

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd flovi_driver
flutter pub get
```

### 2. Configure Supabase

Open `lib/core/supabase_config.dart` and replace the anon key:

```dart
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Get it from: Supabase Dashboard → Your Project → Settings → API → `anon` key.

### 3. Configure Google Sign-In

1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
2. Create an OAuth 2.0 Client ID for Android
3. Package name: `com.flovi.flovi_driver`
4. SHA-1: run `cd android && ./gradlew signingReport` and copy the debug SHA-1
5. Download `google-services.json` and place it at `android/app/google-services.json`
6. In Supabase Dashboard → Authentication → Providers → Google: add your Client ID and Secret

### 4. Configure Supabase redirect URL for OAuth

In Supabase Dashboard → Authentication → URL Configuration → Redirect URLs, add:

```
com.flovi.flovi_driver://login-callback
```

## Run on a device or emulator

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

## Build for Android

### Debug APK (for testing)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

**Step 1 — Create a keystore** (one-time, skip if you have one):

```bash
keytool -genkey -v \
  -keystore android/app/flovi-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias flovi
```

**Step 2 — Create `android/key.properties`** (never commit this file):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=flovi
storeFile=flovi-release.jks
```

**Step 3 — Reference keystore in `android/app/build.gradle`:**

Add before `android {}`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Add inside `android { ... }`:
```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ?
            file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

**Step 4 — Build:**

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Run tests

```bash
# All tests
flutter test

# With coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html   # macOS

# Single test file
flutter test test/core/models/relocation_test.dart
```

## Project Structure

```
lib/
├── core/           # API client, models, auth service, router
├── features/
│   ├── auth/       # Login screen
│   ├── available_jobs/  # Browse + booking flow
│   └── my_jobs/    # Booked jobs view
└── shared/widgets/ # JobCard, StatusBadge
```

## API

Base URL: `https://vfmtrozkajbwaxdgdmys.supabase.co/functions/v1/api`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/relocations` | Get pending (available) relocations |
| GET | `/api/v1/relocations` | Get driver's own relocations |
| PUT | `/api/v1/relocations/{id}` | Book a relocation |
```

- [ ] **Step 2: Add key.properties to .gitignore**

```bash
echo "android/key.properties\nandroid/app/google-services.json\nandroid/app/*.jks" >> .gitignore
```

- [ ] **Step 3: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: add README with Android build instructions and setup guide"
```

---

## Task 14: Generate code (build_runner) and run full test suite

**Files:** (generated)

- [ ] **Step 1: Run build_runner to generate Riverpod and Mockito code**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: Generated files appear in `test/` directories (`.mocks.dart` files).

- [ ] **Step 2: Run the full test suite**

```bash
flutter test --coverage
```

Expected output example:
```
00:05 +12: All tests passed!
```

All tests must pass. If any fail, fix before proceeding.

- [ ] **Step 3: Verify Android debug build**

```bash
flutter build apk --debug
```

Expected: `BUILD SUCCESSFUL` — APK at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "chore: generate Riverpod/Mockito code, verify full test suite passes"
```

---

## Task 15: Create the testing agent

**Files:**
- Create: `.claude/agents/testing-agent.md`

- [ ] **Step 1: Create the agents directory and agent definition**

```bash
mkdir -p .claude/agents
```

```markdown
---
name: testing-agent
description: Runs the full Flovi Driver test suite and reports results. Use when you want to verify all tests pass, check coverage, or investigate a test failure. Triggers automatically after any feature implementation.
---

# Testing Agent — Flovi Driver

You are the testing agent for the Flovi Driver Flutter app. Your job is to run the test suite, interpret results, and report clearly.

## Steps

1. **Run build_runner** to ensure generated mocks are up to date:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Run the full test suite with coverage:**
   ```bash
   flutter test --coverage 2>&1
   ```

3. **Parse and report results:**
   - Total tests run
   - Passed / Failed counts
   - Any failing test: name, file path, expected vs actual values
   - Coverage percentage (read from `coverage/lcov.info` if available)

4. **For each failing test**, report:
   - Test name and file
   - The assertion that failed (expected vs got)
   - The source file most likely responsible
   - A suggested fix

5. **Run static analysis:**
   ```bash
   flutter analyze 2>&1
   ```
   Report any errors or warnings found.

6. **Summary output format:**
   ```
   ## Test Results
   - Total: N
   - Passed: N
   - Failed: N
   - Coverage: N%

   ## Analysis
   - Errors: N
   - Warnings: N

   ## Action Required
   [List of fixes needed, or "All tests passing — no action required"]
   ```

## Test Files

- `test/core/models/relocation_test.dart` — model parsing
- `test/shared/widgets/job_card_test.dart` — JobCard widget
- `test/features/available_jobs/available_jobs_provider_test.dart` — provider logic
- `test/features/available_jobs/booking_sheet_test.dart` — booking flow
- `test/features/my_jobs/my_jobs_provider_test.dart` — my jobs provider
```

- [ ] **Step 2: Commit**

```bash
git add .claude/agents/testing-agent.md
git commit -m "feat: add testing agent for automated test suite execution"
```

---

## Final Verification

- [ ] `flutter analyze lib/` — zero errors
- [ ] `flutter test --coverage` — all tests pass
- [ ] `flutter build apk --debug` — build succeeds
- [ ] `PROMPTS_LOG.md` exists with all teammate prompts
- [ ] `README.md` covers all Android build steps
- [ ] `.claude/agents/testing-agent.md` exists and is well-formed
