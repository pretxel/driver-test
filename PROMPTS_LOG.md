# PROMPTS_LOG.md — Flovi Driver App

A chronological log of every agent action, teammate prompt, and key decision made during the creation of this app.

---

## Session: 2026-04-12

### Brainstorming Phase
- **User:** Provided DEFINITION.md with app requirements
- **Claude:** Explored project context (empty repo + DEFINITION.md)
- **Decision:** Side Drawer navigation (vs Bottom Nav / Home-First Stack)
- **Decision:** Dark Navy + Blue theme (vs Light+Green / Dark+Orange)
- **Decision:** Feature-First architecture with Riverpod 2 + go_router (vs Clean Architecture / Flat)
- **Decision:** Riverpod 2 for state management (vs BLoC / Provider)

### Design Spec
- **Claude:** Presented 3-section design (Architecture, Data/API, Screens/Testing)
- **User:** Approved all sections
- **Output:** `docs/superpowers/specs/2026-04-12-flovi-driver-design.md`

### Implementation Plan
- **Claude:** Wrote full 15-task TDD implementation plan
- **Output:** `docs/superpowers/plans/2026-04-12-flovi-driver.md`

### Execution
- **Tasks 1-15:** Executed via Subagent-Driven Development (fresh subagent per task + two-stage review)
- **Task 1:** Flutter project scaffold — auth-agent
- **Task 2:** Relocation model (TDD) — auth-agent
- **Task 3:** API client + RelocationApi — auth-agent
- **Task 4:** AuthService + Supabase init — auth-agent
- **Task 5:** go_router + dark theme — auth-agent
- **Task 6:** Login screen — auth-agent
- **Task 7:** JobCard + StatusBadge (TDD) — jobs-agent
- **Task 8:** AvailableJobsProvider (TDD) — jobs-agent
- **Task 9:** AvailableJobsScreen + drawer — jobs-agent
- **Task 10:** BookJobProvider + BookingSheet (TDD) — booking-agent
- **Task 11:** MyJobsProvider + MyJobsScreen (TDD) — my-jobs-agent
- **Task 12:** PROMPTS_LOG.md
- **Task 13:** README with Android build instructions
- **Task 14:** build_runner + full test suite
- **Task 15:** Testing agent

---

## Session: 2026-04-13

### Bug Fix — Google idToken is null
- **User:** Reported sign-in failure: "Google idToken is null"
- **Root cause:** `GoogleSignIn` instantiated without `serverClientId`. On Android, `google_sign_in` only includes an `idToken` in the response when a Web Client ID is provided via `serverClientId`. Without it, `googleAuth.idToken` is always `null`.
- **Fix:** Added `googleWebClientId` constant to `lib/core/supabase_config.dart` and passed it as `serverClientId` to `GoogleSignIn()` in `lib/core/auth/auth_service.dart`.
- **User action required:** Set `googleWebClientId` in `supabase_config.dart` to the Web OAuth Client ID from Google Cloud Console (must match what is configured in Supabase → Auth → Providers → Google).
- **Commit:** `fix: pass serverClientId to GoogleSignIn so idToken is populated on Android`

### Feature Update — Available Relocations rename + API fix
- **User:** Requested rename of "Available Jobs" section to "Available Relocations" and API endpoint change to `GET /api/v1/relocations?status=PENDING`
- **Changes:**
  - `lib/core/api/relocation_api.dart` — `fetchPendingRelocations()` now uses `GET /api/v1/relocations?status=PENDING` (was `POST /api/v1/relocations` without query param)
  - `lib/features/available_jobs/available_jobs_screen.dart` — AppBar title, drawer nav label, empty state text all updated to "Available Relocations"
- **Commit:** `feat: rename Available Jobs to Available Relocations and use GET ?status=PENDING`

### Bug Fix — Relocation model mismatch with real API response
- **User:** Provided actual API response JSON; fields differed from assumed model
- **Real API shape:** `id`, `origin`, `destination`, `date`, `notes`, `status`, `userId`, `createdAt`, `updatedAt`
- **Old model shape (incorrect):** `vehicleMake`, `vehicleModel`, `pickupLocation`, `dropoffLocation`, `created_at` (snake_case)
- **Root cause:** Model was designed from spec assumptions before seeing real API output. `createdAt` was camelCase (not `created_at`), and vehicle/location fields did not exist in the API.
- **Changes:**
  - `lib/core/models/relocation.dart` — Removed vehicle/location fields; added `origin`, `destination` (String), `date` (DateTime), `notes` (String?); fixed `createdAt` key to camelCase
  - `lib/shared/widgets/job_card.dart` — Title and location rows updated to use `origin`/`destination`; added date row with `Icons.calendar_today`
  - `lib/features/available_jobs/booking_sheet.dart` — Detail rows updated to origin/destination/date/notes
  - `test/core/models/relocation_test.dart` — Rewritten with real JSON fixture; 6 tests (added notes test)
  - `test/shared/widgets/job_card_test.dart` — Updated to check `'Madrid → Valencia'` and origin/destination rows
  - `test/features/available_jobs/available_jobs_provider_test.dart` — `sampleJob` updated to new constructor
  - `test/features/available_jobs/booking_sheet_test.dart` — Updated to use origin/destination/date fields
  - `test/features/my_jobs/my_jobs_provider_test.dart` — Updated to use Spanish cities with new fields
- **Result:** `flutter analyze` — no issues; `flutter test` — 15/15 passed
- **Commit:** `fix: update Relocation model to match real API response shape`

### Feature Update — My Jobs uses userId query param
- **User:** Requested `GET /api/v1/relocations?userId=<id>` for the My Jobs section
- **Changes:**
  - `lib/core/api/relocation_api.dart` — `fetchMyRelocations()` now accepts `userId` String and passes it as `?userId=` query parameter
  - `lib/features/my_jobs/my_jobs_provider.dart` — Added `currentUserIdProvider` (reads `Supabase.instance.client.auth.currentUser!.id`); notifier reads userId from provider so it is overridable in tests
  - `test/features/my_jobs/my_jobs_provider_test.dart` — Overrides `currentUserIdProvider` with `'user-123'`; verifies `fetchMyRelocations('user-123')` is called

### Feature Update — Booking confirmation endpoint changed
- **User:** Requested `PUT /api/v1/relocations/:id/confirm` for booking a relocation
- **Changes:**
  - `lib/core/api/relocation_api.dart` — `bookRelocation()` now calls `PUT /api/v1/relocations/$id/confirm` (was `PUT /api/v1/relocations/$id`)
- **Result:** `flutter analyze` — no issues; `flutter test` — 15/15 passed
- **Commit:** `feat: use userId query param for my jobs and /confirm endpoint for booking`

---

## Teammate Prompts

### auth-agent
> Implement Tasks 1–6 of the Flovi Driver implementation plan:
> Flutter project scaffold, Relocation model, API client with Supabase JWT interceptor,
> AuthService with Google Sign-In, go_router with redirect guard, and Login screen.
> Follow the plan at `docs/superpowers/plans/2026-04-12-flovi-driver.md`.
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
> error message, and state rollback on failure.
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
