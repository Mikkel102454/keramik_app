# Keramik Android client

Flutter client for the Keramik ceramics journal. Android is the supported MVP target.

## Run

Install Flutter using the version compatible with `pubspec.yaml`, then run:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the Android emulator route to the host. A physical device needs a reachable development URL. Release builds reject a missing or non-HTTPS URL:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Signing credentials are intentionally not stored in this repository.

## Current MVP boundary

Ceramics, clays, glazes, images, and session login are functional. Shop, Profile, Notifications, glaze combinations, textiles, signup, forgot-password, share controls, and the notification badge are intentionally incomplete placeholders. Their current rendering and no-op behavior are preserved; they must not be presented as completed features.

The client expects the backend's `{success, data, error}` envelope for every endpoint. Authentication failures follow the same envelope and route through the normal unauthenticated state. Create and edit forms use the backend's 255-character text limits, required ceramic fields, 0–5 rating, and nonnegative weight rules. Draft images are temporary JPEG files: they are retained after a failed create for retry and removed when deleted, after success, or when the create page is abandoned.

## Validation

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
