# Keramik Android client

Flutter client for the Keramik ceramics journal. Android is the supported MVP target.

## Run

Install Flutter using the version compatible with `pubspec.yaml`, then run:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the Android emulator route to the host. A physical device needs a reachable development URL. Release builds reject a missing or non-HTTPS URL:

Debug builds use `http://10.0.2.2:8080` when `API_BASE_URL` is omitted. Always pass an explicit URL for a physical device, desktop/web debugging, staging, and release builds.

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Signing credentials are intentionally not stored in this repository. The current Android `release` build type still uses debug signing for local execution; it is not publishable until an approved production keystore/signing configuration is supplied.

## Current MVP boundary

Ceramics, clays, glazes, images, session login by email or username, basic profiles, profile photos, account search, friend requests, friendships, blocking, unblocking, encrypted direct messaging, encrypted group chat, message reporting, authenticated WebSocket invalidations, REST backfill, category-aware request/unread badges, account settings, and English/Danish localization are functional. The ceramic journal has a unified grid with client-side search across titles, notes, outcomes, tags, clay, and glaze names; multi-category filters; title/rating/stage/created/updated sorting; improved empty/error states; and a finished-pieces grid on the self profile. Signup with a required email address, account administration, temporary-password replacement, and report review are available through the backend's Thymeleaf website. Shop, glaze combinations, textiles, in-app signup, forgot-password email recovery, share controls, push delivery, and background execution while the app is suspended remain intentionally incomplete.

Ceramic detail records support optional dimensions, ordered repeatable glaze applications with coat counts, outcome notes, planned/completed firing records, server timestamps, and read-only stage history. Glaze and firing editors remain mounted while saves complete, own their text-field lifecycle, and scroll above the on-screen keyboard. The Metric/Imperial setting converts dimensions and firing temperatures only at input/display boundaries; API and persisted values remain centimeters and Celsius. Duplicate/template creation, public sharing, and defect tracking remain intentionally deferred.

The titleless Profile tab uses a compact TikTok-inspired overview with avatar, username, read-only edit view, a tappable friend count, and a three-line Settings and privacy menu. Account search remains on Chats. The settings destination covers account details, in-app password change with website fallback, exports, scheduled deletion/cancellation, privacy audiences, blocked accounts, category-aware notifications, system/light/dark appearance, metric/imperial units, language, support/privacy/about links, and recoverable logout. Push delivery remains labeled Coming later. The Edit Profile view shows self-only forename, surname, username, and public UUID; these fields cannot yet be changed. Search accepts username prefixes of at least three characters and returns only accounts allowed by server-side discoverability. Basic public profiles expose only username, avatar, relationship state, and valid actions.

The Chats tab uses the shared page-title styling and lists direct and group conversations with All/Unread/Groups filters, pagination, pull-to-refresh, unread counts, request routing, and per-user archives. Friend requests and incoming one-message requests share the Requests panel. Friends can open an active direct chat from a profile; non-friends can send one preview and must wait for acceptance. New group is available from the Chats overflow menu and selects 1–49 friends. Every active group member can rename, add their own friends, leave, archive, and send; generated group avatars, member counts, sender labels, and centered system events preserve group context. Former members retain read-only membership-period history, while absence gaps remain hidden after rejoin. The shared navigation badge uses the backend aggregate rather than the first inbox page. Authenticated WebSocket events contain no content; they invalidate the badge, inbox, and matching open conversation, which then reconcile over REST. Stable event IDs are deduplicated, reconnects use bounded exponential backoff, and returning to the foreground performs backfill. Microphone, emoji, and image controls are visible but report “Coming later.”

Long-pressing another account's text bubble exposes **Report message**. The form sends one of the six supported categories, requires an explanation for Other, explains that up to two surrounding messages per side are included, and keeps reporting separate from blocking. Messages sent by the current user and group system events are not reportable.

The client derives `ws://` or `wss://` from `API_BASE_URL` and reuses the persisted session cookie. Release builds therefore require HTTPS and connect with WSS. Android is the supported target; the web connector relies on browser-managed same-site cookies and has not been promoted to the supported MVP target.

Browser/Web is explicitly unsupported for release. The cookie-authenticated API currently disables CSRF and relies on native-client isolation plus `SameSite=Strict`; browser support requires a CSRF-token contract first. See [../PRIVACY.md](../PRIVACY.md) and the backend [operations guide](../keramik_app_backend/OPERATIONS.md) for retention, deployment, backup, and key-management boundaries.

Profile uploads can use the device camera or gallery through the existing image picker. The backend is authoritative for type, size, signature, crop, metadata removal, and JPEG encoding. The public-avatar/cache warning is shown inline without an upload confirmation dialog.

The client expects the backend's `{success, data, error}` envelope for every endpoint. The login field accepts an email address or username and sends it in the established `username` request field for backward compatibility. Authentication failures follow the same envelope and route through the normal unauthenticated state. `PASSWORD_CHANGE_REQUIRED` directs the member to replace an administrator-issued temporary password on the Keramik website instead of presenting a generic network error. Create and edit forms use the backend's 255-character text limits, required ceramic fields, 0–5 rating, and nonnegative weight rules. Draft images are temporary JPEG files: they are retained after a failed create for retry and removed when deleted, after success, or when the create page is abandoned.

## Localization

Flutter generates localizations from `lib/l10n/app_<locale>.arb`, with `app_en.arb` as the template. English and Danish are complete. Every locale file supplies its own native `languageName`; the language settings page discovers generated `supportedLocales`, so adding a compiled ARB locale does not require a client registry or backend change.

To add a language:

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<locale>.arb`.
2. Set `@@locale`, translate every message, and set `languageName` to the language's native name.
3. Rebuild the app (or run `flutter gen-l10n`) so Flutter regenerates `AppLocalizations.supportedLocales`.
4. Run `flutter test test/localization_test.dart`; the test rejects missing keys, required metadata, invalid generated ICU messages, and an empty native language name.

The selected canonical BCP-47 tag is saved through account settings and cached in the application-support directory using `path_provider`. First installation defaults to English. Signed-out sessions retain the last selection, while authenticated account settings override the local cache. A cached or server-provided tag that is not compiled into the app displays English without rewriting the unknown server value.

## Validation

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

These automated checks validate analysis, unit/widget behavior, and debug packaging. Two-client on-device acceptance against real MariaDB, MinIO, Redis, and multiple backend instances remains an external release gate; see the backend operations guide.
