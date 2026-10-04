# Keramik Android client

## Studio redesign

The app now uses a TikTok-inspired monochrome Material 3 theme with cobalt-blue
actions, warm amber highlights, compact forms, simple bottom navigation and a
sidebar on wider layouts. Discover
has a vertically paged photo feed that follows the selected light/dark/system
appearance; Home and Profile share the same ceramic photo previews and tight
portrait grids based on the original Home cards. Their theme-surface metadata
panel shows the title, clay where available, localized stage and star/rating;
card height adapts to text size. Missing/loading/failed-photo icons are centered
in the image area above the metadata panel. Public profile thumbnails also retain
likes. The existing ceramic-sharing picker also reuses the journal preview. Materials, chats and settings use flat rows.
Shared responsive components retain
existing routes, controllers, session/API contracts and save workflows. See
[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for component/layout rules and
[MOBILE_TESTING.md](MOBILE_TESTING.md) for validation evidence. Android remains the
supported target. No new dependency or backend migration is required.

## Unified messaging

Profiles use one Message button for friends and eligible non-friends. Existing
pending, accepted non-friend and terminal chats resolve first. Opening/cancelling
a non-friend draft creates no request; sending creates it. The initiator can
send three text messages total before acceptance. Recipients accept before
replying, and pending requests disable media and ceramic sharing. Message
acceptance does not create friendship. Text retries keep their UUID across lost
responses, including the third message. The complete direct-chat title (avatar, name and intervening space), received
avatars and group sender labels open fresh UUID profiles and refresh the chat
on return.

The additive backend resolution/first-send endpoints must be available before
releasing this client. No migration or dependency change is needed for messaging.
Validation: full Flutter analysis is clean and all 191 tests pass; the backend
test/build passes 317 active tests with 39 opt-in skips and its packaged-media
check. Manual Android/two-device acceptance remains pending.
See [backend contracts](../keramik_app_backend/API_FEATURES.md#unified-direct-messaging)
and [acceptance status](MOBILE_TESTING.md#unified-messaging-and-chat-profile-links-2026-10-03).

## Chat appearance

Direct and group chats follow `../reference/Chat` with Keramik theme colors:
fully rounded text bubbles, received messages on the left with a small sender
avatar at the bottom, and your messages on the right without an avatar.
System events and date separators keep their existing presentation. Group
sender names and received avatars open fresh profiles. The complete direct-chat
header title is one accessible profile button with no pressed animation.

Photos have rounded corners and no surrounding bubble padding; previews retain
the complete aspect ratio within available width, up to 250 by 340 logical
pixels. Loading and retry states occupy the same dimensions. Tapping a photo
opens the existing zoom viewer. Voice messages use a compact play/pause pill,
decorative audio bars and an `m:ss` duration, at the same height as a one-line
text bubble, including loading/retry and enlarged text.

The shared `v2` `MessageComposer` groups input and message controls in one rounded
bar, with a separate camera shortcut alongside it.
Empty drafts show microphone, photo, emoji and ceramic sharing. Any text
(including whitespace or an inserted emoji) replaces microphone/photo with Send;
whitespace-only Send stays disabled. Successful text sends clear the draft and
restore media controls; failures preserve it for retry. Multiline input, the
2,000 Unicode code-point limit, keyboard focus and existing availability/request
restrictions remain in place. A camera shortcut beside the empty bar opens the
camera directly. The photo icon opens the device's photo grid directly; selecting
one image opens a rounded preview with Cancel and Send. Cancelling the initial
selection returns to chat. Send closes the photo preview immediately and shows
the prepared image in the conversation while uploading. Failed sends keep that
image and its retry UUID in the chat.
The grid/albums presentation follows the device's native picker, with no new
photo-library permission or dependency.

Voice recording is inline: hold the microphone to record, release to send, drag
left to open the animated trash lid, then release to discard, or drag up to lock.
Dragging back disarms cancellation; capture continues until release.
The bar shows elapsed time and a cancel/lock guide. A tap or keyboard activation starts locked recording as an accessible
alternative. Tapping Stop on a locked recording ends and sends it automatically.
The client caps recordings at one minute and sends both held and locked clips
at that limit; armed cancellations discard. Failed uploads retain a playable
preview and the retry UUID. Backgrounding or opening another chat surface stops
to preview without uploading. Releasing during startup/permission handling
cancels the pending recording. Received avatars and voice playback controls have
no pressed highlight. No API, database or dependency change is required.

The backend also fixes a concurrent direct-chat read-marker error that could
show Internal server error during the refresh after a voice send. It reloads the
participant row/version while acquiring its lock under READ_COMMITTED, retaining
monotonic read markers and the existing authorization checks.

Chats lay out from the bottom on the first history frame, with the newest row at
scroll position zero. They fetch only the latest 50 messages initially and build
rows/media lazily around the viewport. Scrolling toward the oldest loaded rows
fetches one older cursor page at a time; Load earlier remains an explicit fallback.
Older-page failures keep the cursor/history for retry, and refresh preserves
already loaded history and the visible message. Text,
image, voice and ceramic sends appear immediately as local outgoing messages,
with a small Sending label while the server responds. Failures retain the row
with a right-aligned theme-error-colored Not sent label, neutral explanation and
Retry, following `reference/Chat/fail.jpg`. The text/voice draft remains available.
Retries reuse the logical UUID and replace the local preview with the server
receipt. New sends and failure details scroll into view after layout; ordinary
incoming/refresh events preserve the current reading position.

Local delivery state lasts for the open chat session; it is not a durable offline
queue or proof of delivery. Only server messages enter read markers, pagination,
reporting or shared-card navigation. A lost response can leave an uncertain send
marked Not sent until retried; the existing idempotent endpoint resolves it.
The reference's moderation notice is not fabricated. No API/dependency change
or backend runtime change is required.

Full Flutter analysis is clean and all 272 tests pass. Validation details and
outstanding Android device acceptance are recorded in
[MOBILE_TESTING.md](MOBILE_TESTING.md#bottom-first-lazy-chat-history-2026-10-03).

## Android push, chat media, and Recently viewed

Compatible client/backend changes add optional FCM delivery, encrypted image/voice
messages with preview and authenticated playback/download, an offline categorized
emoji picker, and private Recently viewed journal sorting/clearing. Pending message
requests stay text-only. Recently updated remains the default. Push and media
writes default off; builds without Firebase configuration remain supported.

See [configuration and contracts](../keramik_app_backend/PUSH_MEDIA_VIEW.md),
[validation status](../PUSH_MEDIA_VIEW_STATUS.md) and
[installed Android evidence](MOBILE_TESTING.md) and
[manual test checklist](../MANUAL_TESTING.md). The local V22-V24 migration and
compatible backend restart completed after
explicit approval, encrypted backup and isolated restore rehearsal. Other
existing databases require their own approval. The local test backend now enables
media writes; return to Chats and reopen the conversation to refresh controls.
Default/production media configuration stays disabled until accepted.
Firebase provisioning, real FCM acceptance and rollout to other environments
remain pending.
Flutter analysis and all 173 tests pass; Android debug packaging succeeds without
Firebase. Added packages and generated platform registrants are recorded in
`pubspec.yaml`/`pubspec.lock`; recording/playback are supported on Android.

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

If the app reports a network error, verify backend readiness first: healthy
Docker containers alone do not start Spring Boot. The existing development
environment was recovered on 2026-10-04 with migrations disabled; host and
emulator readiness are `UP`, image storage is reachable and the installed app
matches the latest debug APK. Services are left running for user testing.
See [backend recovery and safe restart](../keramik_app_backend/OPERATIONS.md#android-testing-environment-recovery---2026-10-04).

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

Ceramics, clays, glazes, images, session login by email or username, profiles, profile photos, account search, friend requests, friendships, blocking, unblocking, encrypted direct messaging, encrypted group chat, message-scoped ceramic sharing, message reporting, authenticated WebSocket invalidations, REST backfill, category-aware request/unread badges, account settings, and English/Danish localization are functional. The ceramic journal has a unified grid with client-side search across titles, notes, outcomes, tags, clay, and glaze names; multi-category filters; title/rating/stage/created/updated/recently-viewed sorting; improved empty/error states; and finished-pieces grids on self and visible public profiles. Signup with a required email address, account administration, temporary-password replacement, and report review are available through the backend's Thymeleaf website. Shop, native signup forms, richer public ceramic details/showcases, Firebase provisioning and real-device push acceptance remain pending; configured background notifications use FCM system display.

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

The Profile tab uses a compact TikTok-inspired overview with centered avatar/username, explicit-save profile editor, a real friend count and a Settings and privacy action. The Finished pieces statistic is omitted from the Profile tab; its finished-piece thumbnail grid remains available. Account search remains on Chats. The settings destination covers account details, in-app password change with website fallback, exports, scheduled deletion/cancellation, privacy audiences, blocked accounts, category-aware notifications, system/light/dark appearance, metric/imperial units, language, preferred currency, support/privacy/about links, and recoverable logout. Preferred currency defaults to Automatic, which follows the device region with EUR as the safe fallback, and can be changed to a fixed dropdown value. Push has per-device Enable/Disable, Android permission/status/settings controls and an unavailable state when unconfigured. Clear recently viewed confirms before clearing private view timestamps. Edit Profile validates and saves private forename/surname (1-100 Unicode code points) and public username (3-50) together. It trims surrounding whitespace, checks changed usernames after a 500 ms debounce, retains failed drafts, and confirms before discarding unsaved text. Photos remain immediate and preserve text drafts; the public UUID stays read-only. A username change keeps this device signed in, expires other sessions and reconnects chat; name-only edits leave sessions unchanged. Username/photo visibility follows existing settings and blocking rules. Search accepts username prefixes of at least three characters and returns only accounts allowed by server-side discoverability. Opening a visible result uses the same profile-style presentation and adds a tight grid containing only currently published Finished pieces. Thumbnails use the Home card style and show the image, title, clay, localized stage, rating and likes; their publication detail route retains public rating/outcome information. Private journal details remain owner-only.

The Chats tab uses the shared page-title styling and lists direct and group conversations with All/Unread/Groups filters, pagination, pull-to-refresh, unread counts, request routing, and per-user archives. Friend requests and incoming message requests share the Requests panel. Profiles have one Message button that resolves existing conversations first. Friends without a chat create an active conversation; eligible non-friends open a local text draft, and opening or cancelling it creates nothing. The first successful send creates a request and loads its persisted messages. Its initiator may send three text messages total before acceptance; recipients must accept before replying. Pending requests disable media and ceramic sharing. Declined and blocked conversations stay read-only. Accepting a message request does not create a friendship. Failed text sends retain their UUID for retry, including retries after the third message was committed but its response was lost. The complete direct-chat title, received avatars and group sender labels on text, image, voice, ceramic and publication messages load a fresh profile by UUID; returning refreshes the chat. Unavailable profiles show localized feedback. New group is available from the Chats overflow menu and selects 1–49 friends. Every active group member can rename, add their own friends, leave, archive, and send; generated group avatars, member counts, sender labels, and centered system events preserve group context. Former members retain read-only membership-period history, while absence gaps remain hidden after rejoin. The composer ceramic action opens the owner's journal as standard cards, confirms disclosure, and sends an idempotent ceramic message. Live chat cards preserve the complete image aspect ratio and open a complete read-only detail page whose spaced image pager also avoids cropping, displays weight using the member's Metric/Imperial preference, and starts stage history collapsed. The detail has no edit, stage, upload, delete, tag, glaze, firing, or reshare controls; deleted ceramics remain as localized unavailable cards. The inbox uses the message type for a localized preview. The shared navigation badge uses the backend aggregate rather than the first inbox page. Authenticated WebSocket events contain no content; they invalidate the badge, inbox, and matching open conversation, which then reconcile over REST. Stable event IDs are deduplicated, reconnects use bounded exponential backoff, and returning to the foreground performs backfill. The composer supports gated image/voice draft previews and an offline categorized emoji picker without persisted recents. Sent media follows shared-chat retention; report evidence and authorized exports include media.

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

Ceramics are never published automatically. After creating a Finished ceramic,
the app offers an explicit publication prompt. Changing an existing piece's stage
to Finished saves the stage without a popup; publish it using the detail card.
A missing image leaves creation intact and explains why publication is unavailable.
The detail publication card shows checked/unmet requirements for the Finished stage
and at least one photo. Publish stays disabled until both are met, and updates as
the stage or photos change. A photo-free Finished piece receives an explicit
"Add a photo to publish" message confirming that the piece is saved. Existing
publications can still be unpublished when their stage or photos become ineligible.
The ceramic detail card omits the Everyone audience explanation; the Friends-only
audience warning is still shown when applicable.
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


Voice-send troubleshooting follow-up: the isolated direct/group upload regression
and full backend build pass (310 active tests, 39 opt-in skips). The reported
emulator Send failure remains under investigation; the next manual retry is
needed for its method/status-only trace. See
[task status](../PUSH_MEDIA_VIEW_STATUS.md) for the current findings.

### Voice retry trace update - 2026-10-03

The emulator retry reached the local backend: two POST requests returned 400,
with no service exception logged. A newer 19,640-byte draft has mono AAC-LC
metadata and a 2,043 ms duration; a reconstruction containing only structural
headers and zero-filled audio samples passes the validator. Audio samples,
private metadata, cookies and debug capabilities were not copied.

The backend exception handler now offers DEBUG diagnostics containing fixed
rejection categories or exception class names only. Submitted values, exception
messages, identifiers and recording contents are never logged. This logging is
off by default; the verified local process enables it temporarily alongside
method/status-only access logging. Flyway remains disabled. The full backend
`test build` passed (310 active tests, 39 opt-in skips). The emulator-specific
failure is still unresolved: a further Send on the retained preview is needed
to distinguish malformed multipart handling from media validation. Disable the
temporary local logging after diagnosis; do not clear or reinstall the app
while its draft is pending.

### Packaged backend voice validation fix - 2026-10-03

The retained-preview retry returned HTTP 400 with the fixed category
`MEDIA_FORMAT`. The same synthetic MP4 layout reproduced a parser configuration
failure when launched through the executable JAR, although it passed on the
ordinary test classpath. mp4parser 1.9.56 loads its default box mapping with the
system class loader, which cannot see the nested dependency resource. This is
a backend packaging issue; no audio content or authentication change is needed.

`ChatMediaValidator` now initializes the library's supported box-mapping cache
from its own class loader before parsing. Codec, channel count, duration, size,
box bounds, authorization and encrypted storage rules remain in force. No API,
schema, dependency version or Flutter source change is required. Temporary
exception-handler diagnostics have been removed.

The new `packagedMediaCheck` runs `PackagedMediaSmoke` through the built
executable JAR's loader, without starting Spring, contacting Docker or using
persistent data. It checks valid mono AAC, normalized-output validation and
rejection of stereo/overlong clips. The task has a 60-second timeout and runs as
part of `check`/`build`. Targeted media tests, the emulator metadata reconstruction
under the executable JAR, and the full backend `test build` passed: 310 active
tests, 39 opt-in skips, zero failures, plus the packaged check. The fixed backend
is running locally and reports healthy; media remains enabled and Flyway remains
disabled. Existing database/storage and the emulator draft were preserved.
The user's retained-draft Send remains the final live acceptance check. Flutter
runtime code is unchanged; its prior analysis/173-test results were not rerun
for this backend-only fix.

Library references: [mp4parser box parser](https://github.com/sannies/mp4parser/blob/master/isoparser/src/main/java/org/mp4parser/PropertyBoxParserImpl.java)
and [Spring Boot executable JARs](https://docs.spring.io/spring-boot/specification/executable-jar/).
