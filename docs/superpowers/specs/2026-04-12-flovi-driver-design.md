# Flovi Driver — Mobile App Design Spec

**Date:** 2026-04-12
**Status:** Approved

---

## Overview

A Flutter 3 mobile app for vehicle relocation drivers. Drivers authenticate with Google, browse pending relocation requests, book one with a single tap, and track their booked jobs. The app communicates with a proprietary REST API hosted on Supabase Edge Functions.

---

## Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3 (Dart) |
| Authentication | Supabase (`supabase_flutter`) — Google OAuth |
| State Management | Riverpod 2 (`flutter_riverpod` + `riverpod_annotation`) |
| Navigation | `go_router` — side drawer, named routes |
| HTTP Client | `dio` with Supabase JWT interceptor |
| Theme | Dark Navy + Blue (`ThemeData.dark()` customized) |

---

## Project Structure

```
lib/
├── core/
│   ├── api/             # Dio client, interceptors, endpoints
│   ├── auth/            # Supabase auth service wrapper
│   ├── models/          # Relocation model, enums
│   └── router/          # go_router configuration + redirect guard
├── features/
│   ├── auth/            # Login screen, auth provider
│   ├── available_jobs/  # Browse pending relocations + booking flow
│   ├── my_jobs/         # Booked/in-progress/completed jobs
│   └── profile/         # Driver name/avatar (in drawer)
└── shared/
    └── widgets/         # Reusable UI (JobCard, StatusBadge, etc.)
```

---

## Data Model

```dart
class Relocation {
  final String id;
  final String vehicleMake;
  final String vehicleModel;
  final String pickupLocation;
  final String dropoffLocation;
  final RelocationStatus status;
  final DateTime createdAt;
}

enum RelocationStatus {
  pending,      // Available to book
  inProgress,   // Driver assigned — status: IN_PROGRESS
  completed,    // status: COMPLETED
  cancelled,    // status: CANCELLED
}
```

---

## API Layer

**Base URL:** `https://vfmtrozkajbwaxdgdmys.supabase.co/functions/v1/api`

All requests include `Authorization: Bearer <supabase_access_token>` injected by a Dio interceptor that reads the active Supabase session automatically.

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/v1/relocations` | `POST` | Fetch pending relocations (available jobs) |
| `/api/v1/relocations` | `GET` | Fetch driver's own jobs (IN_PROGRESS / COMPLETED / CANCELLED) |
| `/api/v1/relocations/{id}` | `PUT` | Book a relocation (PENDING → IN_PROGRESS) |

---

## Navigation

```
App Start
  └─ Check Supabase session
      ├─ No session  → /login
      └─ Has session → /available-jobs (home)

Side Drawer (post-login)
  ├─ Available Jobs  → /available-jobs
  ├─ My Jobs         → /my-jobs
  └─ Sign Out        → clear session → /login

go_router redirect guard: any route accessed without a session redirects to /login.
```

---

## Screens

### 1. Login (`/login`)
- Flovi logo centered
- "Sign in with Google" button (uses `supabase.auth.signInWithOAuth`)
- Loading spinner during auth
- No action on cancelled sign-in — stays on screen silently

### 2. Available Jobs (`/available-jobs`)
- Scrollable list of `JobCard` widgets for all PENDING relocations
- Data from `POST /api/v1/relocations`
- Pull-to-refresh
- Empty state: "No available jobs right now"
- Error state: inline message + Retry button
- Tap a card → opens Booking Bottom Sheet

### 3. Booking Bottom Sheet (overlay, no route)
- Shows full job details (vehicle, pickup, dropoff)
- "CONFIRM BOOKING" primary button
- Loading spinner on confirm tap
- On success: dismiss sheet, remove job from available list, invalidate `myJobsProvider`
- On error: snackbar error message, state rolled back — job stays in available list

### 4. My Jobs (`/my-jobs`)
- Tabbed view: IN_PROGRESS | COMPLETED | CANCELLED
- Data from `GET /api/v1/relocations`
- Pull-to-refresh
- Empty state per tab

### 5. Side Drawer
- Driver avatar + name (from Supabase user metadata)
- Navigation links: Available Jobs, My Jobs
- Sign Out button at bottom

---

## State — Riverpod Providers

| Provider | Type | Responsibility |
|---|---|---|
| `authStateProvider` | `StreamProvider` | Supabase auth session stream, drives go_router redirect |
| `availableJobsProvider` | `AsyncNotifierProvider` | Fetches + holds pending relocation list, exposes refresh |
| `bookJobProvider` | `AsyncNotifierProvider` | Executes PUT booking call, updates available jobs state |
| `myJobsProvider` | `AsyncNotifierProvider` | Fetches + holds driver's job history, exposes refresh |

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| Network / API error on list | Inline error widget with Retry button |
| Booking API failure | Snackbar message, optimistic state rolled back |
| Google sign-in cancelled | Stay on `/login` silently |
| Session expired | `go_router` redirect guard sends to `/login` |
| Empty list | Illustrated empty state per screen |

---

## Teammate Assignments

| Agent | Feature | Folder |
|---|---|---|
| `auth-agent` | Google Sign-In, Supabase setup, routing, go_router guard | `lib/features/auth/` + `lib/core/` |
| `jobs-agent` | Browse pending relocations list + JobCard widget | `lib/features/available_jobs/` |
| `booking-agent` | Confirmation bottom sheet + PUT booking API | `lib/features/available_jobs/` (booking flow) |
| `my-jobs-agent` | My Jobs tabbed view + status filtering | `lib/features/my_jobs/` |

---

## Testing Strategy

| Layer | Coverage | Tool |
|---|---|---|
| Unit | `Relocation` JSON parsing, status enum mapping, provider logic | `flutter test` |
| Widget | `JobCard`, booking sheet rendering, login button, empty/error states | `flutter test` |
| Integration | Auth flow, browse → book → confirm in My Jobs | `flutter_test` + `mockito` |

Testing agent runs `flutter test --coverage` and reports pass/fail + coverage summary.

---

## Out of Scope

- Push notifications
- Offline/cache support
- Map view of relocation routes
- Driver earnings / payments
