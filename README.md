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

For the existing local Android emulator, start the backend and its Docker services using the [backend setup guide](../keramik_app_backend/README.md), then run:

```powershell
flutter emulators --launch Medium_Phone
flutter devices
flutter run -d emulator-5554 --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Use the device ID reported by `flutter devices` if it differs. `--no-pub` assumes packages are already resolved; otherwise run `flutter pub get` first. Backend readiness is available at `http://localhost:8080/actuator/health/readiness` on the host and through `http://10.0.2.2:8080/actuator/health/readiness` from the emulator.

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Signing credentials are intentionally not stored in this repository. The current Android `release` build type still uses debug signing for local execution; it is not publishable until an approved production keystore/signing configuration is supplied.

## Shared UI conventions

The existing `v2` UI library provides text/select controls and common entry-page
primitives. Field decoration is shared with the application theme. Glaze entries,
combinations and test tiles use matching Information/domain sections, read-only
details with Edit/Delete, and explicit Save with draft-discard protection. Glaze
titles now save when Save is pressed. Existing clay/piece flows retain their
current save semantics. See [UI_CONVENTIONS.md](UI_CONVENTIONS.md) for component
usage and the required consistency review, and [MOBILE_TESTING.md](MOBILE_TESTING.md)
for installed Android evidence.

## Current MVP boundary

Ceramics, clays, glazes, images, session login by email or username, profiles, profile photos, account search, friend requests, friendships, blocking, unblocking, encrypted direct messaging, encrypted group chat, message-scoped ceramic sharing, message reporting, authenticated WebSocket invalidations, REST backfill, category-aware request/unread badges, account settings, and English/Danish localization are functional. The ceramic journal has a unified grid with client-side search across titles, notes, outcomes, tags, clay, and glaze names; multi-category filters; title/rating/stage/created/updated sorting; improved empty/error states; and finished-pieces grids on self and visible public profiles. Signup with a required email address, account administration, temporary-password replacement, and report review are available through the backend's Thymeleaf website. Shop, native signup forms, richer public ceramic details/showcases, push delivery, and background execution while the app is suspended remain intentionally incomplete.

Ceramic detail records support optional dimensions, ordered repeatable glaze applications with coat counts, outcome notes, planned/completed firing records, server timestamps, and read-only stage history. Owners can save reusable planning-only project templates, create numbered batches of up to 50 ceramics, and safely batch-edit owned journal entries after reviewing a preview. Templates intentionally exclude images, ratings, outcomes, completed firings, stage history, publication, engagement, chat references, and timestamps. Batch edits skip protected glaze/firing work instead of replacing it. Journal selection mode also offers a separate permanent batch-delete workflow with a title review, explicit acknowledgement, stale-item protection, and all-or-nothing ownership enforcement.

Materials → Glazes now exposes Combinations and the Test-tile notebook. Recipes
provide optional clay and planning-only firing defaults; tiles preserve a selected
recipe version and independently record actual layers/conditions, results and up
to 20 private photos. Search, recipe/clay filters, editing/reordering, confirmed
deletion and retry states are available in English and Danish. Saved combinations
preview and append glaze layers only, either to local creation drafts or through
an atomic existing-piece operation with retry receipts and a subsequent refresh.
Notebook editing is Free; existing Maker rules govern new/changed custom coat
counts, including copied/applied counts. See
[the shared contract and validation guide](../keramik_app_backend/GLAZE_NOTEBOOK.md).
The backend must have V21 before these flows are used. The local backend was
subsequently migrated to V21 and restarted after approval, an encrypted backup
and an isolated restore rehearsal; readiness passed. Uncertain application requests retain their UUID
across navigation within the authenticated app session; app termination ends the
in-memory retry context. Installed Android notebook flows and screenshots were
checked on a disposable read-only emulator against isolated H2/MinIO, including
light/dark themes, English/Danish and compact enlarged text. See
[MOBILE_TESTING.md](MOBILE_TESTING.md) for the evidence, repeatable setup and
remaining physical-device/failure checks. Browser acceptance still needs
Playwright MCP, which is unavailable in this session.
Notebook validation (2026-10-02): changed-file formatting and localization
generation completed, `flutter analyze --no-pub` found no issues, and the full
`flutter test --no-pub` suite passed all 156 tests after the shared-UI follow-up. Device testing exposed and
fixed empty pagination values, disabled Create controls and crowded labels;
regression tests cover both list entry paths. Dependencies are unchanged.

The private Practice analytics page aggregates only the signed-in member's records on the backend. It shows created/completed activity, current stages, trustworthy timing samples, structured ratings, material use, successful clay–glaze combinations, firing-target accuracy, and inventory spending/usage. Every section includes its calculation rule and preserves missing data as missing rather than zero.

Materials now includes an optional append-only inventory ledger. Clay is stored canonically in kilograms; each glaze inventory chooses kilograms or litres. Purchases, confirmed usage, edits recorded as reversal/replacement pairs, and explicit reversals explain the stock balance. Purchase and usage costs use decimal strings and a currency selected from a dropdown. Weighted-average usage combines positive costed purchase history, converts its original currencies into the selected estimate currency using the backend's cached ECB reference rates, and then calculates the quantity's cost. Original purchase amounts remain unchanged. Cost and analytics screens also request an estimate in the preferred currency. Usage can be linked through an owned-ceramic picker but is never inferred automatically. When opened from a ceramic, that ceramic is preselected but remains changeable. The Metric/Imperial setting converts kilogram input/display at the boundary.

The titleless Profile tab uses a compact TikTok-inspired overview with avatar, username, explicit-save profile editor, a tappable friend count, and a three-line Settings and privacy menu. Account search remains on Chats. The settings destination covers account details, in-app password change with website fallback, exports, scheduled deletion/cancellation, privacy audiences, blocked accounts, category-aware notifications, system/light/dark appearance, metric/imperial units, language, preferred currency, support/privacy/about links, and recoverable logout. Preferred currency defaults to Automatic, which follows the device region with EUR as the safe fallback, and can be changed to a fixed dropdown value. Push delivery remains labeled Coming later. Edit Profile validates and saves private forename/surname (1-100 Unicode code points) and public username (3-50) together. It trims surrounding whitespace, checks changed usernames after a 500 ms debounce, retains failed drafts, and confirms before discarding unsaved text. Photos remain immediate and preserve text drafts; the public UUID stays read-only. A username change keeps this device signed in, expires other sessions and reconnects chat; name-only edits leave sessions unchanged. Username/photo visibility follows existing settings and blocking rules. Search accepts username prefixes of at least three characters and returns only accounts allowed by server-side discoverability. Opening a visible result uses the same profile-style presentation and adds a read-only grid containing only that member's Finished-piece image, title, stage, clay, and rating; no public journal-detail route is provided.

The Chats tab uses the shared page-title styling and lists direct and group conversations with All/Unread/Groups filters, pagination, pull-to-refresh, unread counts, request routing, and per-user archives. Friend requests and incoming one-message requests share the Requests panel. Friends can open an active direct chat from a profile; non-friends can send one preview and must wait for acceptance. New group is available from the Chats overflow menu and selects 1–49 friends. Every active group member can rename, add their own friends, leave, archive, and send; generated group avatars, member counts, sender labels, and centered system events preserve group context. Former members retain read-only membership-period history, while absence gaps remain hidden after rejoin. The composer ceramic action opens the owner's journal as standard cards, confirms disclosure, and sends an idempotent ceramic message. Live chat cards preserve the complete image aspect ratio and open a complete read-only detail page whose spaced image pager also avoids cropping, displays weight using the member's Metric/Imperial preference, and starts stage history collapsed. The detail has no edit, stage, upload, delete, tag, glaze, firing, or reshare controls; deleted ceramics remain as localized unavailable cards. The inbox uses the message type for a localized preview. The shared navigation badge uses the backend aggregate rather than the first inbox page. Authenticated WebSocket events contain no content; they invalidate the badge, inbox, and matching open conversation, which then reconcile over REST. Stable event IDs are deduplicated, reconnects use bounded exponential backoff, and returning to the foreground performs backfill. Microphone and emoji controls remain future placeholders.

Long-pressing another account's text bubble or ceramic card exposes **Report message**. The form sends one of the six supported categories, requires an explanation for Other, previews the selected content, and keeps reporting separate from blocking. For ceramics it discloses that every current journal field and image is copied immutably with the same-period surrounding context. Messages sent by the current user and group system events are not reportable.

The client derives `ws://` or `wss://` from `API_BASE_URL` and reuses the persisted session cookie. Release builds therefore require HTTPS and connect with WSS. Android is the supported target; the web connector relies on browser-managed same-site cookies and has not been promoted to the supported MVP target.

Browser/Web is explicitly unsupported for release. The cookie-authenticated API currently disables CSRF and relies on native-client isolation plus `SameSite=Strict`; browser support requires a CSRF-token contract first. See [../PRIVACY.md](../PRIVACY.md) and the backend [operations guide](../keramik_app_backend/OPERATIONS.md) for retention, deployment, backup, and key-management boundaries.

Profile uploads can use the device camera or gallery through the existing image picker. The backend is authoritative for type, size, signature, crop, metadata removal, and JPEG encoding. The public-avatar/cache warning is shown inline without an upload confirmation dialog.

The client expects the backend's `{success, data, error}` envelope for every endpoint. The login field accepts an email address or username and sends it in the established `username` request field for backward compatibility. Authentication failures follow the same envelope and route through the normal unauthenticated state. `PASSWORD_CHANGE_REQUIRED` directs the member to replace an administrator-issued temporary password on the Keramik website instead of presenting a generic network error. Create and edit forms use the backend's 255-character text limits, required ceramic fields, 0–5 rating, and nonnegative weight rules. Draft images are temporary JPEG files: they are retained after a failed create for retry and removed when deleted, after success, or when the create page is abandoned.

## Signup and password recovery

The login screen's accessible **Sign up** and **Forgot password** buttons open the
external browser at `/signup` and `/forgot-password`. Set `WEBSITE_BASE_URL` to the
website origin; it defaults to `API_BASE_URL`, and release builds require HTTPS.
Membership continues to use the same origin at `/membership`. URLs contain no
credentials, app cookies, query parameters or automatic return links. Duplicate
launches are prevented and launch failure feedback is localized in English/Danish.

The same account works in both places. After registering or choosing a new
password, return to the app and sign in normally. Recovery signs out existing
sessions/devices. An enabled account awaiting deletion can recover its password;
recovery does not cancel deletion or alter billing. Backend mail setup and rollout
checks are documented in [PASSWORD_RECOVERY.md](../keramik_app_backend/PASSWORD_RECOVERY.md).

## Localization

Flutter generates localizations from `lib/l10n/app_<locale>.arb`, with `app_en.arb` as the template. English and Danish are complete. Every locale file supplies its own native `languageName`; the language settings page discovers generated `supportedLocales`, so adding a compiled ARB locale does not require a client registry or backend change.

The ARB catalogs and generated localization classes are current for English and Danish. `flutter gen-l10n` has completed successfully in the approved validation work; generated files remain derived from `app_en.arb` and `app_da.arb` and are not edited manually.

To add a language:

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<locale>.arb`.
2. Set `@@locale`, translate every message, and set `languageName` to the language's native name.
3. Rebuild the app (or run `flutter gen-l10n`) so Flutter regenerates `AppLocalizations.supportedLocales`.
4. Run `flutter test test/localization_test.dart`; the test rejects missing keys, required metadata, invalid generated ICU messages, and an empty native language name.

The selected canonical BCP-47 tag is saved through account settings and cached in the application-support directory using `path_provider`. First installation defaults to English. Signed-out sessions retain the last selection, while authenticated account settings override the local cache. A cached or server-provided tag that is not compiled into the app displays English without rewriting the unknown server value.

## Validation

Recovery validation (2026-10-02): analysis passes, all 136 Flutter tests pass,
and the Android debug APK builds. The account-link tests also pass with a separate
HTTPS website origin and discard base-path/query values. Backend disposable
MariaDB and Mailpit HTTP/SMTP acceptance pass; installed Android/browser recovery
UX acceptance remains open because Playwright MCP is unavailable in this session.
See [the recovery report](../keramik_app_backend/PASSWORD_RECOVERY.md).

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

These automated checks validate analysis, unit/widget behavior, and debug packaging. Two-client on-device acceptance against real MariaDB, MinIO, Redis, and multiple backend instances remains an external release gate; see the backend operations guide.

Local validation (2026-10-01): `flutter analyze --no-pub` passed and all 121 Flutter tests passed with `flutter test`. The earlier shared-ceramic detail failure was an off-screen lazy-list assertion and now scrolls to the relevant content. The imperial-weight stall was caused by a non-language settings update unnecessarily awaiting the platform locale cache; locale persistence now runs only when the language tag changes. Discover coverage now includes the Shop route, initial/incremental/empty/error feed states, pagination, refresh, duplicate suppression, logical-request UUID reuse after failure, expired-session replacement, image containment/error placeholders, optimistic-like reconciliation and rollback, integrated five-second Not interested/Undo transport behavior, direct create/Finished-transition prompts and non-Finished exclusion, owner published/unpublished state and audience warnings, curated details, published-profile filtering, publication chat sharing and unavailable placeholders, all report categories (including the required stolen-work explanation), validation/request mapping, successful duplicate-report receipt parsing, English/Danish copy, and accessibility semantics. The pagination trigger now runs after the current frame instead of notifying its `AnimatedBuilder` during list construction. The guarded backend Android runner also passes a two-emulator scenario against disposable H2 and real MinIO: two apps authenticate independently; the viewer sees the owner's image-backed publication; Everyone/Friends and block/unblock transitions remove and restore live Discover visibility; owner unpublish removes it after a cold viewer reload; and concurrent viewer-like/owner-unpublish and publication-share/owner-unpublish races leave withdrawn episodes inaccessible. A withdrawn publication message persists and renders the localized unavailable card on the viewer emulator. A separate real-time MinIO run proves the unchanged application-signed image URL works immediately and returns HTTP 403 after 900 seconds. All disposable resources were removed afterward. Recommendation-session expiry timing remains open.
# Discover and publication

The former Shop navigation item is presented as Discover. Authenticated members can
browse For You and Latest publication feeds, refresh and paginate them, like other
members' publications, mark an episode Not interested with a five-second Undo, and
submit publication reports. Duplicate cards are removed by publication UUID and an
expired recommendation session replaces—rather than appends to—the old list.

Ceramics are never published automatically. After creating a Finished ceramic or
moving one into Finished, the app offers an explicit publication prompt. A missing
image leaves the journal mutation intact and explains why publication is unavailable.
Private journal details remain private; profiles request only currently authorized
publication episodes.

The feed uses a social-post layout for continuous vertical scrolling:
creator and publication time above a reserved, height-bounded image frame with
loading progress and uncropped content, like/share actions directly below,
and the creator/title caption and clay metadata at the bottom. Tapping a post opens
its curated detail; tapping the creator header opens their live profile, and
double-tapping an unliked image likes it.

Discover cards and published profile cards open a server-authorized curated detail
view with a height-bounded swipeable image gallery, creator identity, clay, tags, dimensions, outcome, rating,
and like count; private notes, weight, glaze/firing data, and history are not
requested. Publications can be shared through the existing direct/group picker.
Chat renders a live-authorized publication card, refreshes the message-scoped detail
before opening it, and shows a localized unavailable placeholder after authorization
or lifecycle changes. The report dialog localizes every category, validates required
explanations, and explains the immutable evidence copy and permanent episode
suppression.

## Account deletion timing

English and Danish deletion messages describe a cancellation period of at least 30 days. A paid membership can extend deletion until the paid period ends; cancellation remains available before the backend's scheduled deletion date. This wording follows the existing backend policy and does not change the API or retention behavior. The generated localization files come from `app_en.arb` and `app_da.arb`.

Profile editing validation (2026-10-02): localization generation, changed-file
formatting and `flutter analyze --no-pub` passed; `flutter test --no-pub` passed
all 166 tests. The coordinated backend tests/build passed 288 active tests with
25 opt-in tests skipped, and seven additional disposable MariaDB profile tests
passed. Android acceptance covered Save/session continuity, other-session expiry,
discard, photo changes during text editing, and English/Danish light/dark layouts
at 320 dp with 160% text and keyboard visible. See [MOBILE_TESTING.md](MOBILE_TESTING.md)
for evidence and remaining physical-device/iOS limitations.

## Membership and feature allowances

Settings includes Membership with the effective plan, publication usage, preview
state, cancellation/end date, saved-data explanation and manual refresh. The app
loads `GET /api/account/entitlements` after authentication, refreshes on foreground
return and subscription errors, retains only the current session's last result on
network failure, and clears it on logout/account changes. Loading/failure is distinct
from confirmed Free membership. Backend checks remain authoritative.

Discoverable feature actions show localized Maker/allowance explanations. Image,
firing and publication quotas come from the server rather than Dart policy values.
Saved templates have a complete read-only view, inventory/cost history stays
readable, and reversals, ordinary firing edits, exports, unpublishing and deletion
remain available after downgrade. New private ceramic cards require Maker when
enforcement is enabled; receiving/reading cards and public Discover sharing remain
Free. Existing send identities can still replay after expiry.

The upgrade action opens the configured website's `/membership` in the external
browser without app cookies or credentials. Set `--dart-define=WEBSITE_BASE_URL=https://www.example.com`
when the website origin differs from `API_BASE_URL`; otherwise the API origin is
used. Release website URLs require HTTPS. Browser sign-in may be required.

Backend enforcement defaults disabled until coordinated acceptance; the app honors
that preview switch. Unknown feature keys parse safely, and missing known keys are
unavailable. English/Danish ARBs and generated localizations include all membership
copy. The already installed `url_launcher_platform_interface` 2.3.2 is now a direct
dev dependency for the browser-launch test, with no package version upgrades.
See the backend [policy and rollout guide](../keramik_app_backend/ENTITLEMENTS.md).

Subscription validation (2026-10-02): regenerated localizations and changed-file
formatting passed. `flutter analyze --no-pub` passed with no issues and
`flutter test --no-pub` passed all 131 tests. The backend's isolated test suite and
build also passed (241 active tests; seven opt-in tests skipped). Browser/app/Stripe
and disposable-MariaDB entitlement acceptance remain pre-enablement gates;
enforcement is still disabled.
