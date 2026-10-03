# Testing the Android app

Android is the supported mobile target. A passing widget suite or APK build does
not establish that an installed app can use the backend or that its screens look
right. For mobile UI and workflow changes, validate the installed app and inspect
screenshots as well as running focused automated tests. If device access is
unavailable, record that limitation and the exact setup needed; do not mark device
or visual acceptance as passed.

## Safe test environment

Use synthetic accounts, records and images against an isolated backend/storage
pair. Preserve the normal development database, service volumes and app data.
Never clear an existing AVD or phone's app data without explicit authorization.
The normal backend may apply migrations at startup, so do not restart it as part
of mobile acceptance when those migrations have not been separately approved.

Native Android testing can use ADB, accessibility hierarchies and screenshots.
Playwright MCP is required for browser testing when available; its absence does
not prevent native Android testing through an available Android SDK/device.

## Notebook acceptance helpers

The standard-library Python helper
[glaze_notebook_android_acceptance.py](scripts/glaze_notebook_android_acceptance.py)
supports an interactive native acceptance session. It is not an unattended test
suite: use the workflow checklist below, inspect screenshots and record assertions
against the isolated API while exercising the app.

Prerequisites are Windows, Python, Java 21, the resolved Flutter SDK/packages,
Android SDK/ADB with `Medium_Phone_2`, Docker Desktop and the existing pinned local
MinIO/mc images. From this repository:

```powershell
python scripts\glaze_notebook_android_acceptance.py build
python scripts\glaze_notebook_android_acceptance.py emulator
python scripts\glaze_notebook_android_acceptance.py start
```

`build` has an eight-minute packaging limit and writes a fingerprinted APK for
`http://10.0.2.2:18082`. `emulator` uses a read-only, snapshot-disabled copy on
`emulator-5560`; it refuses an already occupied device slot. `start` verifies
read-only emulator ownership and the APK fingerprint/endpoint before installing
or resetting the disposable app copy. It starts Spring's `test` profile on
loopback port 18082 with H2 `create-drop` and Flyway disabled, plus a separately
labeled, unmounted MinIO container on a random loopback port. It creates random
disposable credentials/accounts/materials and signs in through the actual app.
It does not connect to the normal database or restart port 8080.

Useful commands during the session:

```powershell
python scripts\glaze_notebook_android_acceptance.py labels
python scripts\glaze_notebook_android_acceptance.py tap Materials
python scripts\glaze_notebook_android_acceptance.py tap Glazes
python scripts\glaze_notebook_android_acceptance.py capture glazes-entry
python scripts\glaze_notebook_android_acceptance.py api /api/glaze-combinations
```

The helper exposes `tap`, `enter_hint`, `scroll_to`, `wait`, `capture`, `session`
and `request` for observed-control actions and assertions in Python. Use the
actual accessible labels; do not assume a tap succeeded until the destination is
observed. Screenshots are captured after observing the hierarchy and allowing the
frame to settle. Inspect the PNG, not just its accessibility tree.

Finish even after a failed check:

```powershell
python scripts\glaze_notebook_android_acceptance.py stop
```

Cleanup verifies the owned test server, MinIO label and read-only emulator before
stopping them. The local checkpoint is encrypted with Windows DPAPI `CurrentUser`
and deleted after cleanup. Screenshots, private logs and the assertion report are
kept under ignored `build/notebook-mobile-acceptance/`; keep them synthetic and do
not commit credentials or private screenshots. After testing, rebuild the ordinary
debug APK for `http://10.0.2.2:8080` so its default build output does not point at
the stopped acceptance server. Do not install or reset the user's normal app just
to perform this cleanup.

## Workflow and visual checks

For the notebook, exercise these paths and record which ones passed:

1. Materials → Glazes → Combinations/Test-tile notebook. Check loading, empty
   lists, enabled Create controls, search and recipe/clay filters.
2. Create, save, reopen and edit a recipe. Add repeated glazes, reorder layers,
   enter coats/notes and planning-only firing defaults. Verify stored order,
   stable IDs, atmosphere and canonical Celsius values through the isolated API.
3. Create a tile from a recipe version. Edit actual firing/results independently;
   verify the source snapshot and recipe remain unchanged.
4. Pick a synthetic gallery photo, confirm Android's picker, wait for upload,
   inspect the displayed photo and verify image metadata. Check cancellation,
   confirmed deletion and upload-failure recovery separately.
5. Apply a recipe to a piece with existing layers. Inspect the preview before
   confirmation; verify appended orders and preservation of clay, firings,
   photos, notes and history. Check the piece's refreshed display. Also check
   local creation drafts and deliberate repeated applications.
6. Type a draft, press Back, cancel discarding and verify the text remains. Check
   validation, confirmed record deletion, source-recipe deletion with surviving
   tiles, and unavailable material snapshots.
7. Exercise version conflicts, uncertain application retries and plan downgrade.
   Keep device checks distinct from controller/backend fault-injection tests.

Inspect lists, forms, modal dialogs, photo/detail views and application previews
in light/dark themes and English/Danish. Include a compact screen, enlarged text,
long names, open keyboard and scrolling to the last controls. Check overlapping
labels, clipping, accidental word breaks, contrast, reachable actions and
accessible control bounds. Scan the test app's logcat for Flutter layout/errors
without exposing credentials or unrelated device logs.

For the disposable emulator, the compact settings used for this run were:

```powershell
adb -s emulator-5560 shell wm size 960x1704
adb -s emulator-5560 shell wm density 480
adb -s emulator-5560 shell settings put system font_scale 1.3
```

These produce 320×568 logical pixels with 130% text scaling. Apply them only to
the verified disposable copy. The normal comparison used 1080×2400 at density
420. Restore/reset display overrides before comparisons or discard the copy.

## Glaze notebook device results — 2026-10-02

The current debug APK was exercised on the read-only `Medium_Phone_2` copy using
native ADB against isolated H2 and real private MinIO storage. The normal AVD,
port-8080 backend, MariaDB and storage volumes were preserved.

Verified through the installed app and isolated API assertions:

- Recipe list/create/edit/reopen, reordered stable layers and a repeated glaze.
- Planned firing at 1200°C with oxidation atmosphere.
- Tile creation from the selected recipe version, independent completed firing
  at 1210°C and result notes, with the source recipe still planned/unchanged.
- Android gallery selection, picker confirmation, compression/upload and signed
  photo display.
- Application preview and confirmation: three layers appended after an existing
  layer, with the existing entry ID and unrelated piece fields preserved.
- Recipe/clay filtering, search, empty results and restoration of matching results.
- Draft Back/Cancel protection and explicit discard.
- Recipe deletion cancellation/confirmation, with tile source snapshot and photo
  preserved; photo and tile deletion cancellation/confirmation.
- Native English/Danish, light/dark screens and compact enlarged-text form
  scrolling, including reachable result controls.

Device testing found and fixed two functional bugs: unset pagination parameters
were serialized as empty query values (the backend rejected the cursor), and the
Create button did not rebuild when loading finished. Regression tests cover both
recipe and tile entry paths. Visual/accessibility review also led to clearer
heading/field spacing, a separate add-layer semantics region, and a Danish label
that wraps at a word boundary.

Evidence is retained locally in `build/notebook-mobile-acceptance/`: the assertion
report is `results-notebook-20261002.json` (preserved before the UI follow-up);
representative screenshots include
`application-preview-light.png`, `tile-photo-uploaded.png`,
`tiles-list-compact-danish.png`, `tile-snapshot-label-final-compact-danish.png`
and `tile-results-editor-final-compact-danish.png`. The final result field and
source-snapshot label were reviewed again after rebuilding. The current app
process's logcat had no Flutter overflow or unhandled-exception markers.

The full Flutter suite passed 149 tests; analysis and debug packaging passed.
The focused notebook suite has 13 tests. Backend implementation/migration tests
remain documented in [GLAZE_NOTEBOOK.md](../keramik_app_backend/GLAZE_NOTEBOOK.md).
This device run complements those tests; it does not replace MariaDB concurrency,
lost-response, entitlement, export or erasure acceptance.

The installed-app application check used the recipe-detail route. The piece's
glaze-section entry point and local creation-draft application retain automated
coverage but were not separately exercised on this emulator. Remaining device
checks also include unavailable-material UI, physical-device gallery/permission
variants, transport-failure/uncertain-retry and downgrade scenarios. A coordinated
restored MariaDB/MinIO rollout remains separate. Browser acceptance remains
unavailable without Playwright MCP. Native Android access was available for this
run; no additional access was needed for these emulator checks.

## Shared UI consistency follow-up — 2026-10-02

The existing `v2` library now owns field decoration and the matching entry-page
structure; see [UI_CONVENTIONS.md](UI_CONVENTIONS.md). Glaze titles use an explicit
Save in a separate editor, like combinations/test tiles. Field labels remain
accessible when filled, and focusing an unchanged input does not create a draft.

On the installed app against another isolated H2/private-MinIO pair, verified:

- Glaze create/reopen and view → edit → Save. API assertions proved typing did
  not write, Back/Cancel kept the draft, and Save refreshed the detail title.
- Tile create and edit, multiline notes/results, and a saved 1200°C firing using
  the shared dialog. The isolated API confirmed the saved values.
- A filled glaze field retained its accessible name; focusing it and returning
  without edits did not show a discard confirmation.
- Screenshots compared glaze/tile view and edit layouts in normal English light
  mode and 320×568 logical pixels with 130% text in Danish dark mode. The final
  tile result controls were reachable by scrolling. No Flutter overflow or
  unhandled-exception markers appeared in the final app process's logcat.

The full suite passed **156 tests** and the final focused UI/notebook suite
passed **20 tests**. Analysis, localization generation, changed-file formatting,
Python helper compilation and Android debug packaging passed. Regression checks
include failed-save draft preservation/refresh, required names, unchanged Back,
caller-owned controller lifetime, persistent input labels and asynchronous
selection rollback. A rejected-selection regression was corrected in the shared
control before acceptance. No API, dependency or database migration changed.

Evidence remains under ignored `build/notebook-mobile-acceptance/`: `results.json`
records this follow-up, while the earlier notebook report is preserved separately.
Representative final screenshots are `ui-glaze-editor-compact-da-dark.png`,
`ui-tile-editor-final-compact-da-dark.png`, `ui-tile-results-final-compact-da-dark.png`
and `ui-tile-list-compact-da-dark.png`; light screenshots use the `ui-*-light`
prefix. The helper now dismisses the keyboard before page scrolling, swipes in
page padding rather than a multiline input, and locates stable accessible labels.

Docker Desktop was initially stopped. Starting the local engine enabled the
isolated environment; the normal Spring service was not restarted and no existing
database migrations were run. Disposable services/checkpoints are removed after
the session, and the ordinary debug APK is rebuilt for port 8080. The previous
physical-device, transport-failure/downgrade and alternate-application-route
limitations remain. This run reviews the affected page family, not every screen
or every theme/locale/device combination in the app.

## Editable profile acceptance - 2026-10-02

The profile editor uses the shared fields, an explicit Save, a separate text
draft, and a read-only public account ID. Names require 1-100 Unicode code points
and usernames 3-50 after trimming. Valid changed usernames are checked after
500 ms; unavailable/check-failure feedback is localized. A failed Save retains
the draft, including a server-side username conflict after a successful check.
Photo changes remain immediate. Names remain private and changing username keeps
the current device signed in while expiring other sessions.

Automated validation passed `flutter analyze --no-pub` and all **166 Flutter
tests**, including ten profile validation/controller/widget tests. They cover
Unicode boundaries, debounce/stale responses, unavailable/check-failure/retry,
Save conflicts and failure retention, discard, disposal, parent refresh, photo
refresh during editing, saving navigation locks, and compact locale/theme layouts.
Changed-file formatting and localization generation passed. The first sandboxed
localization command was stopped at its two-minute limit with no output; the
single retry with SDK access succeeded.

Installed Android acceptance used a task-owned read-only/no-snapshot copy of
`Medium_Phone_2` on `emulator-5570`, an API on loopback port 18083, disposable H2
with Flyway disabled, and a new unmounted MinIO container with random credentials.
The existing `emulator-5554`, normal backend, app data and existing databases were
preserved. The backend's `bootTestRun` enforces test profile/database isolation.
The task-local helper was adapted from the existing notebook acceptance helper
under ignored `build/`; no credentials are recorded in these notes.

Verified on the installed app:

- Editing text did not write before Save; Back/Cancel preserved the draft.
- Removing a photo preserved unsaved forename text. Save then persisted the
  forename, surname and new username together, refreshed the profile, retained
  the public account ID and kept the current app session signed in.
- A second authenticated session received 401 after the username change.
- English/Danish and light/dark layouts remained usable at 320 dp width and
  160% text scale, with scrolling and keyboard visible. The Danish app-bar title
  ellipsizes at this size while Back and Save remain visible. Long usernames
  scroll within their field. The system keyboard's first-run notice was dismissed
  before the final English dark keyboard screenshot.

Screenshots and the check report remain in ignored
`build/profile-mobile-acceptance/`, using `profile-{en|da}-{light|dark}-compact`
names with field/keyboard variants. The labeled storage container, backend,
read-only emulator and encrypted credential checkpoint were removed after testing.
The ordinary debug APK was rebuilt for port 8080 and checked to exclude the
disposable port-18083 endpoint.
No physical-device or iOS profile acceptance was performed. Actual WebSocket
closure/reconnection, remember-me cookie renewal and former-username reuse are
covered by backend HTTP/WebSocket integration tests; they were not separately
observed through native chat navigation.

The final coordinated backend suite/build passed 288 active tests with 25 opt-in
tests skipped, and seven profile tests passed separately against disposable
MariaDB 11.8.3. Those include database collation, hidden/blocked/lifecycle
reservations, competing claims with complete rollback, and an overlapping-rename
regression that protects the latest session version. The latter uncovered a
snapshot conflict and is resolved by `READ_COMMITTED` for this update plus a
refresh under the owner-row lock. No profile migration or dependency change was
needed. Initial SDK/Gradle waits and test-runner output issues were resolved;
final analysis, suites, backend build and ordinary Android packaging passed.

## Providing device access when unavailable

Install Android SDK Platform Tools and an emulator system image, start an AVD and
verify `adb devices` lists it as `device`. Keep the SDK discoverable through
`LOCALAPPDATA/Android/Sdk`, `ANDROID_HOME`, or an explicitly supplied tool path.
For this helper, create the secondary AVD named `Medium_Phone_2`; retain a separate
normal AVD for personal development data.

For a physical Android phone, enable Developer options and USB debugging, connect
USB and approve the phone's debugging authorization prompt. Resolve `unauthorized`
or `offline` before testing. Supply a reachable development backend URL (the
emulator-only `10.0.2.2` address does not work on a phone), and provide a disposable
test account/data environment. A physical device requires a separate test setup;
this helper deliberately targets only its read-only emulator copy. Permission to
test a device does not authorize clearing its existing app data.


## Android push/media/view acceptance - 2026-10-03

The coordinated implementation is documented in
[PUSH_MEDIA_VIEW.md](../keramik_app_backend/PUSH_MEDIA_VIEW.md) and
[PUSH_MEDIA_VIEW_STATUS.md](../PUSH_MEDIA_VIEW_STATUS.md). Final Flutter analysis
passes with no issues; all 173 unit/widget tests pass. Backend test/build passes
309 active tests, with 39 opt-in tests skipped. Separately, 13 disposable MariaDB
V21-to-V24 tests and real private MinIO media acceptance pass. No normal database
was migrated and no existing service, volume or app data was reset.

Native ADB acceptance used a new read-only `Medium_Phone_2` copy on emulator-5562,
loopback backend 18083 with disposable H2/Flyway disabled, and a new unmounted,
randomly credentialed private MinIO container. The ordinary emulator-5554 and its
running Flutter app were preserved. Credentials are stored only in the owned
Windows-user-encrypted `build/push-media-mobile-acceptance/state.dpapi` checkpoint
until cleanup. APKs, logs, synthetic fixtures, screenshots and non-secret results
stay under the ignored build directory.

Verified on the installed app:

- Successful owner detail display writes a private view timestamp while preserving
  updatedAt. Recently viewed places nulls last. Confirmed Settings clearing and
  owner detail entry from Profile work. Journal resume observes a view written by
  another authenticated session.
- Received images/voice download through message authorization. The image viewer
  preserves proportions; native voice playback opens without an error. The emulator
  is muted, so this does not establish physical-device audio quality.
- Offline categorized emoji inserts and sends a complete Unicode character.
- Native gallery preview/sending and mono AAC Record/Stop/preview/sending succeed.
  First microphone permission resumes into recording after a bounded lifecycle
  wait. Cancellation removes drafts. Backgrounding stops an active recording into
  a preview rather than leaving the microphone running.
- Camera preview and normalization use the Android camera intent. A blocked send
  keeps its preview and permits Cancel. Unblocking preserves the existing blocked
  conversation's read-only history; it does not reactivate that conversation.
  Successful camera sending uses a separate active disposable conversation.
- English/Danish, light/dark and compact 360x640 dp with 1.5x text were checked.
  Final sent-voice controls use the bubble's foreground color. Media placeholders
  reserve image dimensions to avoid shifting content during downloads, and the
  zoom viewer centers its contained image. Danish text and unconfigured push
  controls were inspected on the installed app.

Representative screenshots in `build/push-media-mobile-acceptance` include
`en-light-owned-view.png`, `en-light-recent-sort.png`, `en-light-chat-media.png`,
`en-light-emoji.png`, `en-light-voice-preview.png`, `en-light-image-preview.png`,
`en-light-recording-interrupted.png`, `en-light-clear-confirm.png`,
`en-light-push-unavailable.png`, `en-dark-cross-device-view.png`,
`en-dark-chat.png`, `da-dark-compact-chat-final.png`,
`da-dark-compact-voice-draft.png`, `da-dark-compact-push.png`,
`da-dark-compact-camera-preview.png`, `da-dark-compact-failed-media-draft.png`,
`da-light-compact-chat.png`, `da-light-compact-centered-viewer.png`,
`da-light-compact-camera-preview.png`, `da-light-compact-camera-sent.png`,
`en-light-compact-chat-final.png` and `en-light-compact-voice-final.png`.
Earlier screenshots in the same directory may show the contrast/viewer issue
before its correction; the final files above are identified explicitly.

The new runner reuses the notebook harness's native UI/checkpoint helpers and
requires Python, the Android SDK/AVD, Java 21, Flutter, Docker, the existing pinned
local MinIO/mc images and FFmpeg at the WinGet application link. It rejects occupied
acceptance ports or an existing encrypted checkpoint. Start and stop only its
owned resources; startup failure leaves the checkpoint available for cleanup.

```powershell
python scripts/push_media_android_acceptance.py build
python scripts/push_media_android_acceptance.py emulator
python scripts/push_media_android_acceptance.py start
python scripts/push_media_android_acceptance.py labels
python scripts/push_media_android_acceptance.py capture review-name
python scripts/push_media_android_acceptance.py stop
```

`build` has a 600-second packaging limit; subprocesses, readiness and UI waits are
bounded. Backend `bootTestRun` enforces isolated H2, loopback, create-drop and no
Flyway. The helper disables billing and supplies no Firebase configuration. The
manual native checks do not provision Firebase or touch external accounts.

Real FCM acceptance remains pending until configuration and a registered Android
device are supplied: background, lock screen, terminated process, denied permission,
token refresh, security revocation, authenticated cold-start taps and stale taps.
Android force-stop requires reopening before delivery resumes. Physical-camera,
microphone, audio quality and power-management differences require device checks.
Browser administrator media-review acceptance is pending because no Playwright MCP
was available. Restored MariaDB/MinIO migration and coordinated rollback, normal
rollout, signing and release remain separately authorized operator gates. Push and
new media writes stay off in normal configuration until their acceptance passes.


Cleanup completed after the native run: owned backend port 18083, the labeled
unmounted MinIO container and read-only emulator-5562 were removed; the encrypted
checkpoint was deleted. The ordinary emulator and local services were preserved.
Final journal return logic refreshes metadata even when the detail result contains
no edit. Full Flutter analysis/tests and ordinary debug packaging passed after
this final return-refresh adjustment. The later backend-only mapping correction
protects viewing metadata from stale edits; its isolated/MariaDB/full checks are
recorded in the task status.


The follow-up [manual Android checklist](../MANUAL_TESTING.md) lists user checks,
expected outcomes and configuration prerequisites. A later, separately approved
local backup/restore rehearsal and V22-V24 migration updated the ordinary backend.
It passes readiness with Flyway disabled. A subsequent user-requested local
restart enables image/voice writes explicitly; production defaults and Firebase
push remain disabled. Reopen the active chat to refresh media controls. Nine
isolated media tests and disposable real MinIO acceptance passed again; physical
device capture/audio acceptance is still pending.


## Voice Send failure investigation - 2026-10-03

The user reports the generic error after tapping Send on emulator-5556. The
pending draft's bounded container headers show mono AAC-LC, about 5.55 seconds,
and under 50 KiB. Metadata-only inspection skipped all audio samples. A synthetic
container with zero-filled samples and the same structural layout passes the
validator. Both installed APKs contain the normal local `10.0.2.2:8080` URL.
No recording contents, cookies or debug capabilities were copied.

Added `voiceUploadsBindAndDownloadInDirectAndGroupChatsWithIdempotentRetries`
to ChatMediaTests. It uses the existing synthetic AAC fixture to exercise actual
voice binding, retry identity, recipient download and revalidation in direct/group
chats. The targeted test passes. Full `gradlew.bat test build` also passes:
310 active tests, 39 opt-in skipped, zero failures/errors (349 total). Java
formatting passed. Flutter source was inspected but not changed in this step.

The local media-enabled/Flyway-disabled backend is running with temporary Tomcat
access diagnostics restricted to `%m %s` (method/status only). Readiness is UP.
No request paths, account IDs, bodies, cookies or audio are logged by this setting.
The log locator is in ignored `build/voice-diagnostics/access-log-location.txt`.
No new POST was observed after enabling this trace. The actual emulator failure
is NOT yet reproduced or fixed; a manual retry on the existing preview is needed
for its HTTP status. Keep the draft and logical UUID; do not reset app data.
Remove these temporary access-log CLI options once the failure is resolved.

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

## Unified messaging and chat profile links (2026-10-03)

The new `test/unified_messaging_test.dart` contains 18 automated checks covering
one Message button, draft cancellation without writes, friend chat creation,
existing pending/accepted/terminal chat reopening, first-send persistence and
history loading, the three-text limit, lost first/third response retries, pending
text-only controls, recipient acceptance, fresh UUID profile navigation, safe
unavailable-profile handling, and refresh after returning. Group labels cover
TEXT, IMAGE, VOICE, CERAMIC and PUBLICATION. English/Danish light/dark layouts
pass at 360×740 with 2× text scaling and a simulated 240-pixel keyboard inset;
guidance scrolls in the history so it cannot displace the composer.

Backend service/concurrency/HTTP checks use isolated H2, including simultaneous
first-send retries, competing sends for the final slot, encryption, request
conversation badges, outbox events, privacy/block/account denial, text-only
pending restrictions, acceptance without friendship, friendship activation,
authentication, validation, envelopes and additive fields. No existing database
or storage was migrated or modified for these checks.

Manual/device acceptance for this messaging change has **not been performed**.
The automated layout checks simulate keyboard space; they are not on-device
keyboard, screenshots, screen-reader, permission or two-device acceptance.
Existing push/media acceptance above remains a separate feature's evidence.

Before release, make the additive backend endpoints available, then check with
two test accounts:

1. Open/cancel a non-friend draft and verify no request or badge appears. Send
   the first, second and third texts; confirm the recipient sees one request
   badge and the sender sees waiting after three. The recipient cannot reply.
2. Accept and exchange texts/media/ceramics; confirm friendship remains absent.
   Reopen via the profile after acceptance/unfriend, and retain read-only history
   after decline/block/unblock.
3. Interrupt the first/third send response, retry the retained text and verify
   one persisted message per attempt and no extra allowance consumed.
4. Tap direct usernames and group sender labels on every message type after a
   rename, block or account unavailability; verify fresh profiles, graceful
   failure and refreshed chat state after returning.
5. Check English/Danish, light/dark, enlarged text, portrait/compact screens and
   the actual Android keyboard, with both writable and exhausted requests.

Validation commands use the installed Flutter tool snapshot because the batch
launcher exceeded its two-minute bound with no output in the sandbox. Only that
task-owned process was stopped; generation succeeded on its one permitted retry.
No existing Flutter processes were stopped.

Final Flutter validation: localization generation completed successfully;
only task-modified Dart files were formatted; full `flutter analyze --no-pub`
passed with no issues, and full `flutter test --no-pub` passed all **191 tests**.
These used the installed SDK's `dart.exe flutter_tools.snapshot` entry point and
two-/five-minute process-tree bounds. Initial analyzer brace findings and the
keyboard overflow were fixed. Media profile tests now navigate while actual
attachment widgets are loading, rather than waiting for a download to settle.

Final backend validation: `gradlew.bat --no-daemon test build` passed **317 active
tests** with **39 opt-in skips**, zero failures/errors, and the executable-JAR
packaged-media check. This includes the new concurrent HTTP final-slot test:
one send returns 201, one returns 409, and replaying the winner persists no extra
message. The text dispatcher avoids caching a mutable conversation before
locking; pair-locked user entities refresh before availability checks. Backend
validation used a five-minute process-tree bound and completed in 71 seconds.

Messaging files created: `test/unified_messaging_test.dart`; backend
`dto/DirectChatResolutionDto.java`, `dto/requets/chat/CreateDirectMessageRequest.java`
and `service/DirectChatHttpTests.java` (under their existing source/test packages).
Modified client files: `objects/chat_dto.dart`, `repositories/chat_repository.dart`,
`ui/pages/profile/basic_profile_page.dart`,
`ui/pages/notification/conversation_page.dart` and its controller, both ARB
catalogs and their three generated localization files. The separate
`ui/pages/notification/message_request_page.dart` was removed after reference
checks. Modified backend files: `controller/api/ChatController.java`,
`dto/DirectConversationDto.java`, `service/DirectChatService.java`,
`service/ChatConversationService.java`, `service/GroupChatService.java`,
`service/ProfileMapper.java`, and the direct-service/concurrency test classes.
Existing unrelated push/media/view changes were preserved.

Documentation reviewed and updated: both READMEs, this guide,
`keramik_app_backend/API_FEATURES.md` and `../ARCHITECTURE_REVIEW.md`.
`UI_CONVENTIONS.md`, both repository `AGENTS.md` files and the backend
`OPERATIONS.md` were reviewed; their workflows remain applicable without edits
for this additive change. No messaging dependency or migration was introduced.


## Chat reference styling (2026-10-03)

This client-only change follows `../reference/Chat` using existing theme colors.
It introduces the shared `v2` `MessageComposer`, fully rounded bubbles, received
sender avatars, one continuous direct-header profile target, bare rounded photo
previews (250 by 340 logical-pixel bounds), and compact voice pills with decorative
bars and `m:ss` durations. The initial pass retained recording/preview/explicit
Send; the media-flow follow-up below supersedes that recording interaction.
Existing media gates, request acceptance, stable retry IDs, reporting, pagination
and shared-card/profile navigation remain in place. No contract, backend,
database or dependency changes were made.

Automated coverage in `test/chat_styling_test.dart` checks header avatar/name/gap/
trailing-space taps and button semantics without pressed highlights; received-only
avatars and profile routing across direct/group text, image, voice and both card
types; rounded bubbles and bottom avatar alignment; typing/whitespace/emoji/clear/
sending transitions; Unicode limits and keyboard retention; failed-send draft
retention with stable retry IDs; voice duration/loading/retry/play-pause state;
and photo geometry through loading/error/retry plus the zoom viewer. Compact
320-pixel layouts with 2x text, keyboard insets, English/Danish and light/dark
variants are widget checks, not device acceptance. Existing messaging/report/card/
media regression tests also run.

Final validation completed successfully:

- `flutter gen-l10n` regenerated the three locale files from the English/Danish
  catalogs, adding accessible Play/Pause voice-message labels.
- `dart format` completed for the six changed Dart source/test files.
- `flutter test --no-pub test/chat_styling_test.dart test/unified_messaging_test.dart
  test/chat_report_test.dart test/ceramic_chat_test.dart
  test/publication_chat_sharing_test.dart test/push_media_view_test.dart` passed
  all 54 targeted tests.
- `flutter analyze --no-pub` found no issues.
- `flutter test --no-pub` passed all 213 tests, including the 22 new styling tests.
- `git diff --check` passed.

All Flutter/Dart commands were bounded by the workspace timeouts.
Localization generation initially hit its two-minute timeout with no output
because the sandbox could not acquire the SDK-cache write lock. Its process was
stopped and the single retry with SDK-cache access completed successfully.
A new real-file media fixture was stopped after its fake-clock cleanup stalled;
the final fixture uses a controlled loader and local image file. Photo retry
coverage exposed and fixed a pre-existing Future-returning `setState` callback.

Manual/device acceptance for this styling change has **not been performed**.
On Android, check the following in direct and group chats in English/Danish,
light/dark, compact width, enlarged text, and with the keyboard open:

1. Tap direct-header avatar/name/gap/trailing title space; confirm a fresh profile,
   no pressed animation and refreshed chat on return. Tap each received avatar
   and group sender name. Own messages/system events have no sender avatar.
2. Type multiline text, insert emoji, clear, send successfully, fail and retry.
   Check media/Send swaps, whitespace rejection, retained draft/keyboard and the
   three-text pending-request/acceptance gates. Media/share availability stays
   restricted until acceptance and server media availability.
3. Send portrait, landscape and tall photos; inspect complete proportions,
   rounded corners, stable loading/retry geometry and zoom/close navigation.
4. Follow the recording-gesture acceptance steps in the media-flow follow-up
   below. Check `m:ss`, loading, retry, play/pause/completion, single active
   playback, and pause on navigation/backgrounding. Bars remain decorative.
5. Long-press each received message type and open Report; open ceramic/publication
   cards, including unavailable cards. Check earlier-history pagination, date
   separators and centered system events alongside received avatars.

Documentation reviewed: `README.md`, `UI_CONVENTIONS.md`, this guide,
`../ARCHITECTURE_REVIEW.md` and repository instructions. The first three were
updated. Backend message/conversation DTOs were inspected for compatibility;
backend files were not changed. No cross-repository follow-up or approval is
required for this styling change.


Styling files created: `lib/ui/widgets/v2/message_composer.dart` and
`test/chat_styling_test.dart`. Modified: `lib/ui/pages/notification/conversation_page.dart`,
`lib/ui/widgets/chat_attachment.dart` (already present as uncommitted user work),
`lib/ui/widgets/v2/ui_library.dart`, both ARB catalogs and their three generated
locale files, plus `test/unified_messaging_test.dart` (one frame wait after typing,
with all assertions retained). Existing unrelated work was preserved.


## Chat recording and image-picker flow follow-up (2026-10-03)

The later locked-auto-send and scrolling follow-up supersedes the locked Stop
and time-limit behavior described in this historical validation.

The requested reference interaction now replaces the former Record/Stop sheet.
Hold the inline microphone to record, release to send, drag left then release to cancel, or
up to lock. Tap/keyboard activation starts a locked recording. Locked Stop opens
an inline preview with playback, Cancel and Send. Recording is capped at one
minute; held recordings send at the limit, locked recordings stop to preview.
Background/navigation interruption stops to preview without uploading. Very short
clips (under 300 ms) are discarded. Releasing during permission/startup prevents
an unattended recording. Failed sends preserve the file and logical retry UUID.
Uploading disables cancellation/duplicate send and back navigation.

The photo button immediately opens the native photo grid/albums and the separate
camera button opens the camera. Initial selection cancellation returns to chat;
selection opens one rounded preview with Cancel/Send and a change-photo shortcut.
Images retain the existing JPEG compression, 5 MiB bound and EXIF removal. Only
temporary app-cache copies are cleaned up. The picker uses the existing
`image_picker` package and device UI; the reference's custom gallery styling,
video tabs and multi-image sends are not introduced. No broader gallery access,
new dependency or shared contract is needed. Avatar and voice playback targets
suppress pressed darkening/splash while retaining navigation and semantics.

`test/chat_media_flow_test.dart` adds 23 checks for held/locked recording,
cancellation, startup/permission/Stop races, disposal, interrupted recordings,
removed media access, the duration limit, retry UUID/file retention, duplicate
upload prevention, all four gesture paths after swapping the composer, immediate
photo/camera selection, photo cancellation and retained failed-image retry.
English/Danish, light/dark and compact 320-pixel layouts with 2x text are widget
checks. Existing styling tests also verify received-avatar feedback suppression.
The gesture tests exposed Tooltip consuming microphone holds, which is corrected
by microphone semantics without a competing tooltip recognizer. The compact
Danish check exposed an unbounded drag label; it is now a single line, with full
guidance above the bar and accessible text retained.

Final validation completed successfully, within workspace command timeouts:

- `flutter gen-l10n` regenerated English/Danish labels from the catalogs.
- `dart format` completed for the nine changed source/test files.
- `flutter test --no-pub test/chat_media_flow_test.dart test/chat_styling_test.dart
  test/unified_messaging_test.dart test/push_media_view_test.dart
  test/chat_report_test.dart test/ceramic_chat_test.dart
  test/publication_chat_sharing_test.dart` passed all 77 targeted checks.
- `flutter analyze --no-pub` found no issues.
- `flutter test --no-pub` passed all 236 tests.
- `git diff --check` passed.

No native device acceptance has been performed for this follow-up. Required
Android checks:

1. Hold and release a clip; confirm one sent message. Drag left then release, cancel the pointer
   or press Cancel; confirm no upload. Drag up, release, then Stop; confirm automatic Send.
   Tap the microphone and test accessibility activation of the locked alternative.
2. Test first permission grant/denial, release while permission/startup is pending,
   backgrounding and navigation during capture, and rapid Cancel while Stop runs.
   Confirm microphone capture ends and no unintended message is sent.
3. Fail a held/locked upload, retain and play the preview, retry, and confirm one
   logical message. During upload, verify no double submit, cancellation or back.
   Check held and locked recordings at the one-minute limit.
4. Open the photo grid directly, select/cancel one photo, and open the camera
   directly. Check capture cancellation, portrait/landscape preview, failed-send
   retention/retry and change-photo behavior. Native grid/albums can vary by OS.
5. Tap received avatars and message play/pause controls and confirm no pressed
   darkening. Repeat compact/large-text, keyboard, English/Danish and light/dark
   checks, including pending-request and server-media gates.

Created: `lib/app/chat_voice_draft_controller.dart`,
`lib/app/chat_image_preparation.dart`, `lib/ui/widgets/chat_voice_composer.dart`
and `test/chat_media_flow_test.dart`. Modified: the conversation page, image draft,
shared `v2` composer, attachment playback style, both ARB catalogs and generated
locale files, and styling tests. Reviewed and updated this checklist, README and
UI conventions; reviewed the architecture guide and repository instructions.
The backend media controller/repository contract was inspected and remains
compatible; backend files were unchanged. No cross-repository follow-up or
approval is pending. Existing unrelated workspace changes were preserved.

## Voice read-marker and cancellation follow-up (2026-10-03)

Voice playback pills now match the scaled height of a one-line text bubble in
play, pause, loading and retry states. A left drag arms cancellation, opens the
trash lid with a transition and keeps recording. Release discards; moving back
disarms and release sends. Armed recordings discard at the one-minute limit.
English/Danish gesture guidance and generated localization files were updated.

The server log for the reported error showed MariaDB error 1020 on the direct
participant row. The refresh after a send marks the latest message read, and
overlapping refreshes could reuse a stale managed participant/version. The
backend now atomically refreshes that row with a pessimistic write lock under
READ_COMMITTED. A deterministic regression forces a newer competing read marker
to commit before an older request locks the row; it verifies success, monotonic
read position and idempotent retries. This regression also runs against disposable
MariaDB. Audio validation, upload contracts, authorization and storage stay intact.

Changed client files: voice draft controller, shared composer, inline voice bar,
conversation page, attachment pill, both chat tests, ARBs/generated localizations,
README and UI conventions. Changed backend files: DirectChatService,
PushAndViewTests (inherited by the isolated MariaDB tests), README, media guide
and OPERATIONS. The workspace PUSH_MEDIA_VIEW_STATUS was also updated.
Reviewed the architecture guide and both repository instructions. Unrelated
changes were preserved. No schema/API/dependency change or migration of existing
data is needed.

Validation completed, within workspace timeouts:

- `flutter gen-l10n` and changed-file `dart format` passed.
- `flutter test --no-pub test/chat_media_flow_test.dart test/chat_styling_test.dart
  test/unified_messaging_test.dart test/push_media_view_test.dart`: 74 passed.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 240 passed.
- Backend focused `gradlew --no-daemon test --tests ...PushAndViewTests
  --tests ...ChatMediaTests --tests ...ChatConcurrencyTests`: 27 passed.
- `scripts/verify-push-media-mariadb.ps1 -Disposable`: 14 passed against a new
  unmounted MariaDB container, including the read-marker race; its resources
  were removed by the guarded helper.
- Full `gradlew --no-daemon test build`: 318 active tests passed, 40 opt-in
  checks skipped, zero failures/errors. `packagedMediaCheck` passed mono AAC,
  normalization and rejection limits under the executable JAR loader.
- Both repositories' `git diff --check` passed.
- Restarted the inspected local development backend using the tested JAR and
  its existing launch arguments: readiness UP, `dev`, media enabled and Flyway
  disabled. Existing app data, database and storage were preserved.

The first regression attempt exposed Hibernate's stale-version check during
entity lock acquisition: refreshing after that query was too late. The fix
refreshes with the write lock in one operation. The unchanged assertions then
passed on both databases. The widget regression also waits for the deliberate
closing transition before expecting the outgoing trash widget to disappear.

Native microphone/gesture and retained-draft Send acceptance
remain pending; do not clear/reinstall the app to test a retained draft. Check
the opening/closing lid transition, release-only discard, moving back to Send,
locked recording and the one-minute armed-cancel case on Android. Confirm an
ordinary voice Send refreshes without the reported server error.

## Locked voice auto-send and sent-message scrolling (2026-10-03)

The later optimistic-delivery follow-up supersedes this historical description
of failed sends preserving reading position and waiting for acknowledgment.

Locked recordings now send automatically both when Stop is tapped and at the
one-minute limit. Held release/time-limit sends remain; armed cancellation still
discards. Backgrounding, lost media access and navigation retain a preview,
and failed automatic sends preserve the file/UUID for explicit retry. English
and Danish locked-recording guidance and generated localizations were updated.

Text, ceramic, image and voice acknowledgments share a send revision. The page
animates to the latest row after layout and rechecks the lazy list's changing
extent, with a bounded number of corrections. Attachment receipts enter the
message list before REST reload, so the just-sent item is visible even if refresh
fails. Ordinary incoming refreshes and failed sends do not force scrolling.

Changed: voice draft controller, inline voice composer, conversation page and
controller, both chat tests, ARBs/generated localization, README and UI conventions.
Reviewed the architecture guide and client instructions. The backend media guide
and workspace task status were updated for the changed client workflow. Backend
runtime code/contracts, configuration, dependencies and persistent data are
unchanged; no backend validation or runtime restart is required for this follow-up.
Unrelated workspace work was preserved.

Focused coverage checks locked Stop/time-limit auto-send, failed retry retention,
foreground/access restrictions, variable-height histories for both chat types
and all message types, and scroll preservation on incoming refresh/failure.
Final validation completed within workspace timeouts:

- `flutter gen-l10n` regenerated locked-recording guidance; changed-file
  `dart format` passed for the six source/test files.
- `flutter test --no-pub test/chat_media_flow_test.dart test/chat_styling_test.dart
  test/unified_messaging_test.dart test/ceramic_chat_test.dart
  test/publication_chat_sharing_test.dart`: all 87 passed.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 255 passed.
- Client and backend-document `git diff --check`: passed. The workspace root has
  no Git repository; its changed status section passed a direct whitespace check.

An initial widget run waited on an unpumped mock refresh; its identified process
tree was stopped before the timeout, and status/diff were inspected. Media scroll
fixtures also hit asynchronous app-cache waits when run together. Tests now pump
the refresh and use the existing attachment loader seam through the page to
isolate media loading, with unique fixture IDs. Scroll assertions were retained;
both focused and full suites pass without relying on native cache/network work.

Device checks remain pending: locked Stop and one-minute Send; failed automatic
upload preview/retry; sending while scrolled up, with the keyboard shown/hidden,
and with portrait images/shared cards above the new message. Confirm that reading
older messages is preserved during ordinary refreshes and cancellation.

## Optimistic chat delivery and opening position (2026-10-03)

The later bottom-first/lazy-history follow-up replaces the initial post-layout
jump described here with bottom-first layout on the first history frame.

Chats open at the latest row after the first successful history load. Text,
voice, images and shared ceramics appear locally as soon as Send/upload starts.
Sending becomes a server receipt or a retained Not sent row, with theme error
color, gray localized explanation and Retry, matching the failure placement in
`reference/Chat/fail.jpg`. No moderation ban or delivery receipt is invented.
Retry reuses the UUID, replaces the preview and clears a matching text draft.
Text/voice drafts survive failure. Photo Send closes the preview and transfers
its private prepared file; failed sends retain it, while success/disposal cleans
it after any active upload. Voice discard removes its failed local row.

Local state lasts for the open chat session, without a durable offline queue.
Server history, read markers, pagination, reporting and shared-card routes use
only acknowledged IDs. Unknown delivery after a lost response remains failed
until idempotent retry confirms the receipt. Ordinary incoming/profile/refresh
loads preserve the reading position; enqueue, acknowledgment and failure details
move to the latest row, including Retry above the keyboard.

Created `local_chat_send.dart` and `test/chat_delivery_test.dart`. Updated the
conversation page/controller, image draft, voice draft discard callback,
attachment loader documentation, existing chat styling/media tests, both ARBs
and generated localizations. Reviewed architecture/instructions and matching
backend DTO/idempotency/multipart contracts. Updated README, UI conventions,
this checklist, backend media guide and workspace task status. Backend runtime
code/contracts, dependencies, schema, services and persistent data are unchanged.

Coverage includes a gated server reply proving that outgoing text is visible
before persistence, failure/row retry in English/Danish and light/dark at compact
width with enlarged text and a keyboard, initial positioning across direct/group
variable-height histories, ordinary-refresh preservation, photo file transfer
with full proportions, failed image/voice file retention, stable retry IDs,
locked voice retry/cancel integration, ceramic preview and in-flight disposal
cleanup. An acknowledged first-message preview also stays visible if its history
refresh fails, then reconciles on the next successful load without sending again.
Windows upload fixtures drain multipart streams like a real transport
before checking deletion; assertions and real file cleanup remain enforced.
The enlarged failure-row test caught an off-screen Retry action: failure layout
now advances the scroll revision to keep the action reachable.

Final validation completed within workspace timeouts:

- `flutter gen-l10n`: generated the three delivery labels in English/Danish.
- Changed-file `dart format`: passed.
- `flutter test --no-pub test/chat_delivery_test.dart test/chat_styling_test.dart
  test/chat_media_flow_test.dart test/unified_messaging_test.dart
  test/chat_report_test.dart test/ceramic_chat_test.dart`: all 98 checks passed.
- `flutter analyze --no-pub`: no issues after correcting two brace-style findings.
- `flutter test --no-pub`: all 267 tests passed, including the subsequently added
  first-send/history-refresh regression.
- Client `git diff --check` and direct whitespace checks for new files/backend
  media guide/workspace status: passed. No backend build is needed for docs-only
  changes; its service/runtime was not changed or restarted.

Device acceptance remains pending:

1. Open long direct/group chats containing portrait photos, voice and cards;
   verify the latest message is visible immediately. Read older history, refresh
   or return from a profile and verify the position stays there.
2. Delay/fail text, photo, voice and ceramic sends. Confirm immediate outgoing
   previews, Not sent/Retry placement and absence of false delivered/restriction
   claims. Retry a lost response and verify no extra server message is created.
3. Confirm photo Send closes its preview while uploading, failed photos remain
   viewable and retryable, and Cancel/Back/session end clean private drafts.
4. Verify failed locked/released voice retry and cancel, Stop/time-limit auto-send,
   and release-only animated-trash cancellation on Android.
5. Repeat with English/Danish, both themes, compact widths, enlarged text and
   keyboard shown/hidden; Retry must remain reachable. Incoming refreshes should
   not interrupt reading older history.

## Bottom-first lazy chat history (2026-10-03)

The previous opening helper rendered chronological history from the top and then
jumped to its estimated bottom. Chat now uses a reversed lazy list: newest row
at index/scroll position zero, visible on the first history frame. No initial
jump, animation, extent estimation or older-row construction is needed. The API
was already bounded to the latest 50 messages; this limit remains unchanged.
Scrolling near the older edge fetches one cursor page, with an explicit Load
earlier fallback, duplicate in-flight protection, end-of-history stopping and
retained history/cursor on failure. Automatic retries stop after failure until
an explicit retry. Latest-page refresh merges server IDs and retains older pages
already loaded. Visible message anchors survive incoming/refresh changes and date
separators moving during pagination. New sends/failure feedback still scroll to zero.

Changed `conversation_page.dart`, `conversation_page_controller.dart` and
`test/chat_styling_test.dart`; added `test/chat_lazy_history_test.dart`. Reviewed
architecture/client instructions and both backend message pagination services.
Updated README, UI conventions, this checklist, backend media documentation and
workspace status. No backend code, API, schema, dependency, runtime or service
change is needed; ownership and visibility filters remain unchanged.

The five new tests model a 1,000-message conversation and inspect its first
history frame before settling, for direct/group chats. They assert zero scroll
offset, newest row inside viewport, off-screen oldest rows unbuilt, only 50
messages fetched and lazy media loading. They also cover automatic one-page
fetch, duplicate triggers, stable content anchors, retained pages/cursors across
refresh, failure/retry and a null cursor at history end. Existing variable-height
send/refresh tests now assert the visible message position rather than treating
the top of a forward list as the older reading position. The new tests caught
a date-separator anchor shift; anchors now use message content. Visibility is
checked by viewport bounds because a full-width outgoing row's center is blank.

Final validation completed within workspace timeouts:

- Changed-file `dart format`: passed for the page, controller and both tests.
- `flutter test --no-pub test/chat_lazy_history_test.dart test/chat_styling_test.dart
  test/chat_delivery_test.dart test/unified_messaging_test.dart`: all 69 passed.
- `flutter analyze --no-pub`: no issues after correcting one brace-style finding.
- `flutter test --no-pub`: all 272 passed.
- Client `git diff --check` and direct whitespace checks for the new test/backend
  media guide/workspace status: passed. No backend build/restart was required.

Android acceptance remains pending: open long chats and confirm no top-history flash, scroll upward
through several older pages, retry an older-page failure, and check stable reading
positions after profile return/incoming updates. Repeat with tall media/cards,
English/Danish, both themes, compact width, enlarged text and keyboard visible.
