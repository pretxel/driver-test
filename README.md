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

**Step 3 — Reference keystore in `android/app/build.gradle.kts`:**

Add before `android {}`:
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
```

Add inside `android { ... }`:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
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
