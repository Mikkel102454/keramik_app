# Testing the Android app

## Local testing refresh after export generation (2026-10-04)

The latest source debug APK was rebuilt successfully with:

```powershell
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:8080
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

Installation returned `Success`; `-r` preserves existing app data. No Flutter
source, API contract, dependency or generated-code change was needed. Native
HTTP probes from the emulator verify backend readiness `UP` and MinIO HTTP 200.
After explicit approval, the existing local database was upgraded through
V25/V26 following encrypted backup and network-isolated restore rehearsal; all
58 existing application table row counts were preserved before worker activation.
The tested generation JAR is running with media enabled, Hibernate validation
and Flyway disabled. Host/emulator readiness is UP; anonymous exports return
401 and private MinIO access returns 403. Existing-account export generation and
download/open acceptance remain manual: use Settings and privacy to create an
export, wait for READY and download it. Isolated content/failure/large-archive
acceptance is recorded in backend OPERATIONS. See [backend activation evidence](../keramik_app_backend/OPERATIONS.md#local-testing-readiness-after-bounded-export-generation).

## Bounded export downloads (2026-10-04)

`test/export_download_test.dart` exercises the real AccountRepository and shared
Dio cookies/session interceptors with isolated synthetic streams and ephemeral
loopback services only. It checks exact valid ZIP bytes, distinct private cache
paths, publication only after EOF/length verification, malformed/short/oversized
lengths, interrupted streams, source cancellation, written-partial removal,
completed-file preservation after a failed retry, subsequent successful retry,
ordinary chunked responses, premature HTTP EOF, before-header/mid-body receive
timeouts, downloads progressing beyond the inactivity duration, cancellation
before headers with a late response, and 404/500 versus 401 session behavior.
Page disposal cancels the scoped token; localized feedback is unchanged.

A valid 128 MiB single-entry STORED ZIP is generated from a reusable 64 KiB zero
block and fixed-size ZIP metadata with the known CRC32. The test checks that the
source never gets more than one 64 KiB chunk ahead of disk, verifies the resulting
header/directory and the entire stored payload in bounded reads. Neither fixture
creation nor verification collects the large ZIP. This guards against Dio 5.9's
eager internal response queue; the scoped adapter gates raw chunks on disk-write
acknowledgement. Backend checks separately transfer a generated 128 MiB ZIP with
a 64 MiB heap and verify a real TCP disconnect closes storage without an active
database transaction. Interrupted storage transfers abort promptly without JSON
conversion, private error details or stack traces.

```powershell
flutter test --no-pub test/export_download_test.dart test/network_timeout_test.dart
flutter analyze --no-pub
flutter test --no-pub
```

Validation passed: `flutter analyze --no-pub` found no issues (8.9 seconds), all
370 Flutter tests passed (63 seconds), and targeted export/timeout coverage
passed all 38 tests. These checks do not connect to the normal backend, MinIO,
MariaDB or external accounts. No dependency/localization generation, migrations,
normal-service restart or deployment is needed.

On this Windows session the initial `dart.bat format` stalled without output and
was stopped at its two-minute limit. The direct installed Dart executable with
`--suppress-analytics` successfully formatted only changed files. Flutter analysis
and tests ran through the installed `flutter_tools.snapshot` with the same CLI
arguments and ordinary SDK cache access; no SDK sources or project dependencies
were changed.

Remaining acceptance: real private-MinIO/proxy and installed physical Android
file opening/cache-eviction behavior. Files are temporary cache entries, and
generation still uses large in-memory structures. Process death can leave a
task-owned partial for Android cache eviction; no crash scavenger is introduced.
Disk exhaustion/permission errors take the failure-cleanup path, but storage
hardware failures can also prevent deletion. No full ZIP checksum/structure
validation, concurrency budget, automatic retry or resume is added; a clean
lengthless chunked truncation cannot be detected from HTTP byte count alone.

## Android backup allowlist (2026-10-04)

The three policies allow exactly `domain="file" path="language-tag.txt"`:
`backup_rules.xml` for API 24-30, plus both `cloud-backup` and `device-transfer`
in `data_extraction_rules.xml` for API 31+. Adding an include makes all unlisted
paths/domains ineligible; no directory or wildcard is included. There is no
cross-platform transfer section, custom BackupAgent, storage relocation or data
clearing code.

Paths were verified against the resolved installed package, not inferred from
Dart directory names. `.dart_tool/package_config.json` resolves
`path_provider_android` 2.3.1. Its `lib/src/path_provider_android_real.dart`
implements support with JNI `Context.filesDir` and documents with
`Context.getDir("flutter", MODE_PRIVATE)`. The disposable emulator's app root was
`/data/user/0/nu.miguel.kemik_app`; the relevant mappings are:

| State | Path relative to app root | Backup mapping / policy |
| --- | --- | --- |
| Language preference | `files/language-tag.txt` | `file`, `language-tag.txt`; sole include |
| Push installation UUID and opt-in | `files/push-device.json` | `file`, `push-device.json`; unlisted |
| Cookie jar | `app_flutter/cookies/ie0_ps1/` | `root`, `app_flutter/cookies/`; unlisted |
| Firebase files/preferences, private media, drafts, databases, other state | Any other path/domain | Unlisted; excluded |

`cookie_jar` 4.0.9 appends `ie0_ps1/` to the application's existing documents
cookie directory (`ignoreExpires: false`, default session persistence). Native
startup after restore independently produced that directory. No Dart, API,
authentication, push lifecycle, dependency or signing code was changed.

Automated validation passed:

- `flutter analyze --no-pub`: no issues (8.5 seconds).
- `flutter test --no-pub`: all 357 tests passed (69 seconds), including existing
  network-timeout/session-preservation tests.
- `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:18994`:
  succeeded (109 seconds). This endpoint was a temporary loopback unauthenticated
  fixture, not the normal backend. No Firebase defines or credentials were used.
- `android\gradlew.bat -p android :app:processProfileMainManifest :app:processReleaseMainManifest --console=plain`:
  succeeded (47 seconds), without release signing/build/publication.
- `py scripts/verify_android_backup.py`: passed for debug/profile/release merged
  manifests, the compiled APK manifest's resource IDs and both packaged binary XML
  resources. The verifier rejects broad includes, missing D2D rules, cross-platform
  rules and custom backup agents. APK min/target SDK values were 24/36.

The first sandbox Flutter launcher was stopped with no output; its single bounded
retry with installed SDK access succeeded. No unrelated process was terminated.
The first manifest invocation used a forward-slash Windows launcher path and
failed before Gradle ran; the absolute-path invocation succeeded. The verifier's
initial Windows text decoding was corrected to UTF-8. Gradle reported existing
plugin namespace/deprecation warnings; there were no unresolved build failures.

Native validation used a newly created `BackupPolicyDisposable` AVD with its own
fresh disk under ignored `build/android-backup-acceptance/avds/`, dedicated
`emulator-5580`, no snapshots and no signed-in Google account. The installed image
was `android-37.1/google_apis_playstore_ps16k/x86_64`; the guest reported Android 17,
API 37. The existing `emulator-5554`, other AVD disks and physical devices were
never cleared, reinstalled or restored. Only the disposable app was cleared or
uninstalled during these probes.

Thirteen synthetic files covered language (`da`), push UUID/opt-in (`enabled:true`),
a cookie subtree, a Firebase installation marker, Firebase token/messaging shared
preferences, private media, a cached voice draft, a documents draft, a database,
root/file-domain unlisted files and a nested language-name decoy. Replace-install
preserved all file hashes, including a previous debug APK without explicit backup
rules replaced by this APK. These are synthetic preservation checks, not a live
server-session or configured-FCM delivery test.

Cloud-mode LocalTransport was selected and initialized with `bmgr`; the encrypted
test-transport flag was enabled. A never-launched/stopped app first reported
`Backup is not allowed`. After launch/background and package-manager backup
initialization, package-specific backup succeeded. The test required
`Package nu.miguel.kemik_app with result: Success`, rather than relying on the
overall backup message. Clearing only this disposable app and executing
`bmgr restore 1 nu.miguel.kemik_app` returned `restoreFinished: 0`. Before startup,
the sole restored file was `./files/language-tag.txt` containing `da`; all twelve
unlisted seeded files were absent. Startup against the loopback 401 fixture showed
**Log ind** and recreated an empty cookie directory. `push-device.json` remained
absent. Existing push code starts opted out and generates a new UUID when configured
without that file; real Firebase initialization was intentionally not exercised.

The available Google D2D transport was initialized with
`backup_enable_d2d_test_mode=1` and successfully backed up the same synthetic state.
Direct restore from its D2D Restore Set returned `restoreFinished: -1000`. The
documented uninstall/switch-to-GMS/reinstall flow also did not restore the language
within its 45-second deadline. Test mode was disabled afterward. **D2D restoration
remains an outstanding acceptance check**, not a passing transfer test. Also open:
API 24-30 runtime restore (no legacy image installed), actual account-backed cloud
restore and real/OEM device transfer. LocalTransport validates Android's cloud-rule
branch without a real cloud account; it does not establish those provider results.

Evidence is retained locally in ignored `build/android-backup-acceptance/`:
build/analyze/test/manifest logs, `packaged-manifest.txt`, compiled rule dumps,
`cloud-backup.log`, `cloud-restore.log`, `cloud-restored-files.txt`,
`restored-login.xml`, D2D backup/restore logs, `runtime-paths.txt` and old/new APK
fingerprints in `update-preservation.txt`. The disposable emulator was stopped
after validation. No normal backend/service, migration, external account, signing,
deployment, commit or push was involved.

Reproduction: build and process the manifests with the commands above (use a
ten-minute APK-build limit and five-minute analysis/test/manifest limits), then run
the verifier. For restore acceptance, create a **new** AVD/data disk, verify its
identity and use explicit `adb -s <disposable-serial>` for every command. Seed only
synthetic data at the mapped paths, compare hashes across replace-install, choose
and initialize a supported local/test transport, launch/background the app and
initialize backup metadata before package backup. Check package-specific success
before clearing that disposable app and restoring its listed set. Check file
exclusion before startup, then language/sign-in; repeat for D2D and legacy Android.
Follow [Android's backup testing guide](https://developer.android.com/identity/data/testingbackup)
for transport-specific steps. Never adapt the clear/uninstall/restore steps to an
existing user emulator or phone. A missing/failing transport remains a release
acceptance item.

## Bounded network timeouts (2026-10-04)

`test/network_timeout_test.dart` exercises the actual shared client with synthetic
cookies and temporary directories. Real IO tests use random loopback ports for
delayed headers, a flushed chunk followed by a stalled body, a progressing response
longer than its inactivity limit, a stalled upload stream and a refused connection.
A stalled connection factory verifies connection timeout without relying on an
external unroutable address. Tests shorten transport limits to milliseconds;
separate assertions verify the production 10/30/30-second defaults. The refused
connection allows three seconds because Windows can delay TCP refusal reporting.

Test doubles cover entitlement/chat-download overrides, ZIP export inheritance,
interrupted image/voice multipart uploads, retained local files and retry IDs,
voice-preview recovery, retained profile/login drafts, history/loading recovery,
and session/cookie preservation during startup checks, authenticated checks and
failed logout. A simulated server commits a chat message before losing its response;
explicit retry uses the same UUID and returns one logical message. English/Danish
widget checks verify timeout feedback and the Unconfirmed label. Existing login
throttling tests remain part of full validation. No existing backend data is used.

Run with the workspace limits (two minutes for generation/formatting; five minutes
for analysis/tests):

```powershell
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub test/network_timeout_test.dart
flutter test --no-pub
```

Only changed Dart files are formatted. The installed native Dio adapter applies
sendTimeout to the upload phase; receiveTimeout resets between response chunks.
Transport expiry does not establish rollback. For operations without an existing
idempotency key, inspect/reload authoritative state before submitting again.
Timeouts do not extend draft lifetimes or create an offline queue. Existing finite
per-request limits and download cleanup remain in place; no mutation retries are
added automatically.

Final validation: localization generation and changed-file formatting succeeded;
`flutter analyze --no-pub` reported no issues; `flutter test --no-pub` passed all
357 tests, including 25 new timeout tests and existing login-throttling coverage.
`git diff --check` passed. The initial sandbox SDK launcher stalled with no output:
generation reached its two-minute deadline and formatting was stopped. Only those
task-owned process trees were terminated; the bounded SDK retry succeeded with
local SDK permissions. Two initial loopback fixtures were corrected to flush the
body explicitly and allow Windows TCP refusal timing. The existing committed-but-
lost-response styling fixture now asserts Unconfirmed while retaining scroll and
same-UUID retry checks. No unresolved automated failures remain.

Physical Android/Wi-Fi-loss acceptance remains a device check: against disposable
data, interrupt a save/upload, verify loading ends and drafts remain, refresh to
check whether the mutation committed, and retry chat with its retained UUID.
Verify the session remains usable and repeat English/Danish feedback checks.
No normal-service restart, backend migration, deployment or persistent-data action
is needed for this client-only change.

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

## Whole-app studio redesign acceptance (2026-10-04)

The redesign preserves Material 3, AutoRoute, the existing feature controllers,
repositories and authenticated API contracts. `test/studio_layout_test.dart`
checks the production light/dark themes, all five root destinations, compact and
wide navigation, large text, system bottom insets, keyboard-visible entry forms,
journal card placeholders and journal error/retry/empty behavior. Automated
validation totals are recorded with the final project validation below; these
checks do not substitute for the native observations in this section.

Native Android evidence uses a read-only, no-snapshot copy of `Medium_Phone_2`
on `emulator-5560`, a synthetic account, an isolated test-profile H2 backend on
loopback port 18082 (Flyway disabled), and labeled disposable MinIO without
mounted persistent storage. The ordinary app, backend on 8080, AVD snapshots,
database and storage volumes are untouched. The acceptance APK is fingerprinted
and compiled with `API_BASE_URL=http://10.0.2.2:18082`; it is not the normal
development APK. Reinstallation uses `adb install -r` to preserve the synthetic
session and fixture data.

The existing backend acceptance task selected a packaged-media smoke main class
and exited before serving requests. A temporary ignored Gradle init script sets
only this isolated `bootTestRun` invocation to `nu.miguel.kemik_app.Main`; no
backend source, configuration, credentials or API were changed. Native input
automation also needed an explicit Back immediately after a known-open keyboard:
the older helper's keyboard visibility probe could otherwise issue an extra Back
on this Android version. Those fixture issues are distinct from product defects.

Evidence is stored locally in ignored `build/studio-mobile-acceptance/`, with PNG
screenshots and matching Android accessibility hierarchies. Inspected observations:

| Configuration | Native coverage and result |
| --- | --- |
| S22+ equivalent, 1080×2340 pixels, density 450 (384×832 logical), three-button navigation | All five roots in light and dark; settings and the appearance sheet; no important root action behind the Android navigation bar. |
| S22+ equivalent, dark | Clay list/detail, glaze list/detail, empty combinations notebook, inventory, project templates, practice analytics, profile editor and group creation load through their existing routes and use the shared theme. |
| S22+ equivalent, dark, software keyboard | The last outcome field in the ceramic creation form accepts long text and remains reachable above the keyboard; the form scrolls without overflow stripes. Account search accepts input with its field visible above the keyboard and shows its empty result. |
| Small phone, 960×1704 pixels, density 480 (320×568 logical), 2× system font scale | Form labels and long outcome text wrap within a scrollable form; group creation remains scrollable with the keyboard. Initial bottom navigation labels fragmented into short word pieces. The final APK was reinstalled and inspected: the active destination now has its complete label, other destinations retain accessible icon targets, and no fragmented labels remain. |
| Tablet-equivalent, 1600×2000 pixels, density 320 (800×1000 logical) | The materials hub uses two columns and retains bottom navigation; all destinations remain reachable above the Android tablet taskbar. |
| Wide landscape, 2560×1600 pixels, density 320 (1280×800 logical) | Materials use two columns with side navigation. A 25-piece synthetic journal uses four lazy columns with image placeholders and long titles; detail navigation remains available. |
| S22+ equivalent, gesture navigation, dark | Discover and the journal keep app navigation above the Android home indicator. Switching overlays briefly made the native hierarchy unavailable; a subsequent stable screenshot/hierarchy succeeded. |
| S22+ equivalent, light, initial loading | A three-second pause of only the verified isolated Java process produced a real inbox loading spinner. The process was resumed in `finally`; the inbox then loaded normally with the authenticated session intact. |
| S22+ equivalent, light, direct conversation and keyboard | An accepted request and seven messages between two synthetic local accounts show incoming/outgoing themed bubbles, newest-message positioning and a multiline draft composer with its Send action above the keyboard and three-button navigation. |
| S22+ equivalent, dark, real backend unavailable | After stopping only the verified disposable backend at the end of the session, Discover and the journal show clear themed errors with reachable Try again actions. Tapping each action retries and safely returns to the error while the backend remains unavailable. |

Representative evidence includes `materials-s22-light.png`,
`profile-empty-s22-dark.png`, `appearance-sheet-s22-light.png`,
`piece-outcome-keyboard-s22-dark.png`, `piece-outcome-small-dark-scale2.png`,
`clay-detail-s22-dark-final.png`, `glaze-detail-s22-dark-final.png`,
`notebook-empty-s22-dark-final.png`, `inventory-s22-dark-final.png`,
`templates-empty-s22-dark-final.png`, `analytics-empty-s22-dark-final.png` and
`profile-edit-s22-dark-final.png`, `user-search-keyboard-s22-dark-final.png`,
`new-group-keyboard-small-dark-scale2.png`, `materials-800-dark-final.png`,
`materials-1280-dark-final.png` and `journal-long-1280-dark-final.png`.
Screenshots without `final` were captured
before the last presentation fixes and may show the debug banner.

Latest-source preview and recheck captures use `latest`:
`materials-small-light-scale2-latest.png`,
`journal-small-light-scale2-latest.png`, `journal-s22-light-latest.png`,
`materials-s22-light-latest.png`, `conversation-s22-light-latest.png` and
`conversation-keyboard-s22-light-latest.png`; dark conversation is
`conversation-s22-dark-latest.png`. Actual failure/retry evidence is
`discover-backend-stopped-s22-dark-latest.png`,
`discover-retry-error-s22-dark-latest.png`, `journal-error-s22-dark-latest.png`
and `journal-retry-error-s22-dark-latest.png`. The actual loading/recovery frames
are `chats-loading-s22-light-final.png` and
`chats-recovered-s22-light-final.png`. The earlier file named
`discover-loading-delay-s22-dark.png` captured the preceding journal frame during
navigation, so it is not evidence of a Discover loading state.

Native review found an empty-journal FAB covering the introductory copy. The
empty journal now hides unused search/filter controls and that FAB, keeping the
explicit first-piece action visible. Reinstalled-source evidence
`journal-empty-s22-dark-final.png` was inspected: the overlap is resolved, the
create action is above both navigation bars and the debug banner is absent.

Final automated validation completed within the configured timeouts:

- Changed-file formatting and localization generation passed.
- `flutter analyze --no-pub`: no issues, 14.9 seconds.
- `flutter test --no-pub`: 302 passed, 185 seconds. The final login pending-deletion
  feedback guard and its new regression were then checked with the five existing
  login tests: all six passed in five seconds (303 unique tests verified across
  those runs).
- The first full-suite attempt exceeded its 300-second limit while a save prompt
  retained an active spinner. The presentation flow was corrected and the bounded
  full-suite runs then completed; no timed-out command remains running.
- Final isolated API-18082 debug APK built successfully. The ordinary API-8080
  debug APK was subsequently rebuilt successfully in 57.3 seconds and remains at
  `build/app/outputs/flutter-apk/app-debug.apk`; it was not installed or used to
  reset the ordinary app.

The final APK's app-process-scoped Flutter runtime log was inspected after the
normal flows and intentional backend failure. It contains no RenderFlex/overflow,
framework exception, unhandled exception, failed asset or disposed-state error
patterns. This is scoped evidence from this session, not a guarantee about every
possible flow. The backend-unavailable retry was exercised while offline; recovery
after that specific failure is covered by automated tests. Native initial-loading
recovery was observed before the backend was stopped.

The documented acceptance cleanup verified ownership, stopped the read-only
emulator and removed only the labeled unmounted disposable MinIO container and
encrypted synthetic checkpoint. Screenshots, build fingerprints, runtime logs and
the non-secret observation list in `results.json` remain in the ignored evidence
directory. The normal development APK uses port 8080 and the ordinary app/data
were not installed over, cleared or migrated.

Physical Samsung hardware, TalkBack,
hardware-keyboard focus order, voice/photo permissions and complete chat delivery
workflows remain separate device checks. This session does not claim native
acceptance for iOS/web/desktop: Android is the documented supported MVP platform.

## TikTok-style refinement acceptance — 2026-10-04

This section supersedes the earlier warm studio appearance. The existing Material
3 theme now uses neutral light/dark surfaces, pink actions, compact flat rows and
tight journal/profile photo grids. Discover presents the existing image
publications in independent vertically paged For You/Latest feeds with a side
action rail. Caption and rail have persistent theme-derived backing for contrast
over bright images. There are no new video, comment or follower features.

Architecture, controllers, repositories, API/session contracts, localization and
Android support remain unchanged by this refinement. No dependency, backend
source change, migration or stored-data change was needed. Backend configuration
and documentation changes from the earlier local-service restoration remain in
place; the backend was inspected without further changes for this UI pass.

Automated validation completed within the configured limits:

- Changed-file `dart format` passed; `git diff --check` passed.
- `flutter analyze --no-pub`: no issues, final recheck 4.4 seconds.
- `flutter test --no-pub --reporter expanded`: all 316 passed, 37 seconds.
- Thirteen new feed tests cover independent tab positions, vertical swiping,
  like identity, hide/Undo and failed-hide recovery, last-page reconciliation,
  320/384/800-landscape/1280 widths, both app themes, 2× text and system insets.
- Existing settings tests now scroll to offscreen rows and allow their scroll
  animation to settle before tapping. Existing pagination tests request more
  data only after swiping onto the loading page. Their behavioral assertions
  remain; obsolete duplicate-header expectations were removed.
- Native accessibility hierarchy review found a duplicate creator-avatar focus
  target. The avatar now uses one actionable username tooltip and excludes its
  decorative initials. A new regression verifies the semantics tooltip, button
  and tap action and absence of the initials node. The older widget test now
  checks the labeled active IconButton instead of the removed wrapper.
- Ordinary debug APK build with `--target=lib/main.dart` and
  `API_BASE_URL=http://10.0.2.2:8080`: passed, final build 13.0 seconds.

The ordinary APK was installed with `adb install -r` on `emulator-5554`, preserving
the logged-in session, existing pieces and images. All five roots and Settings
were opened and visually inspected in the existing dark appearance. No messages,
piece/material changes or preference changes were made. The app is left on Home.
Backend readiness returned `UP` on port 8080; existing database, storage and cache
services remain running without migrations or data deletion.

The ordinary artifact at `build/app/outputs/flutter-apk/app-debug.apk` and the
installed package have SHA-256
`3f38ea8f94dacd908589d8647bd9ebb26edb6e6bb68289c171914421a069e3a0`.
It is the normal development build, not the synthetic QA build.
The final normal package was reinstalled after the avatar semantics fix and its
Home screen rechecked. App-process-scoped logs contain zero framework exception,
RenderFlex/overflow, unhandled exception, failed asset or disposed-state patterns
in this observed session.

Current evidence is in ignored `build/tiktok-mobile-acceptance/`, including the
full-suite/analysis/build logs and `ordinary-home-final-dark.png`,
`ordinary-materials-dark.png`, `ordinary-discover-dark.png`,
`ordinary-chats-dark.png`, `ordinary-profile-dark.png` and
`ordinary-settings-dark.png`. The ordinary account has no finished public pieces,
so its Discover/Profile empty states were checked without creating user data.

Additional native state checks use only a read-only, no-snapshot AVD on
`emulator-5560`. An ignored fixture entry point renders the production widgets
with synthetic controller/API responses and images served by an ephemeral
Android-loopback HTTP server. Its adapter never delegates to the ordinary backend.
The fixture APK is fingerprinted and installed only on that disposable AVD.
Synthetic images are host-precomputed PNGs: an earlier fixture-only offscreen
Canvas/toImage startup caused a Windows emulator access violation; replacing that
fixture generation allowed startup to succeed. The ordinary production build
started and ran normally throughout. No production workaround was required.
Android viewport/navigation-overlay changes can recreate this fixture and reopen
its initial feed. Native automation checks the current hierarchy and returns to
the fixture launcher before starting a new phase. A gesture-named launcher capture
was rejected as evidence and replaced only after checking the actual feed.

Inspected native observations for this refinement:

| Configuration | Evidence and result |
| --- | --- |
| S22+ equivalent, 1080×2340 pixels, density 450 (384×832 logical), three-button navigation, light and dark app themes | Production journal, materials, profile, settings and feed screenshots show the neutral/pink styling, compact rows, dense photo grids and reachable app navigation above the system bar. Discover deliberately retains its dark media surface in both app modes. |
| S22+ equivalent, populated feed | Like changes 128→129; vertical swipe moves to the next post; Latest advances independently and For You retains its prior position. Hide/Undo preserves a valid current publication. Information opens the real production detail page and its loopback-served photo. The menu exposes existing hide/report actions. |
| S22+ equivalent, asynchronous states | Empty and initial loading states render; failed initial loading shows Try again and retry recovers populated content. A missing image shows its placeholder while retaining actions. Failed hide restores the publication and shows localized feedback. |
| Small phone, 960×1704 pixels, density 480 (320×568 logical), dark, 2× native text scale | Feed, journal, materials, profile and settings remain scrollable. Navigation keeps the complete active label and accessible icon targets. Long material labels wrap, profile statistics wrap, and feed captions/rail can scroll independently. |
| Small phone, dark, 2× native text scale, software keyboard | The journal search accepts `bowl` with the real IME visible and focus above it. Dismissing the keyboard preserves the query and filters the nine-piece fixture to six results. |
| S22+ equivalent, light, software keyboard | `home-search-keyboard-s22-light.png` shows the focused `bowl` query above the real IME, six filtered photos and the Create action above the keyboard/system bar. Dismissing the keyboard retains the six results. |
| Landscape-equivalent, 1600×768 pixels, density 320 (800×384 logical), dark, 2× native text scale | The feed rail scrolls to Share/Information/More without paging the photo. More opens its existing menu. The caption also scrolls; no action is hidden behind app/system navigation. |
| Final-source S22+ equivalent | `feed-s22-light-final.png/xml` confirms the creator avatar has one clickable/focusable username target and no separate decorative-initials target. The caption username remains a separate intentional creator link. |
| Final-source S22+ equivalent, gesture navigation | The corrected `feed-s22-light-gesture-final.png/xml` shows the actual populated feed, reachable rail/navigation and the Android home indicator below app navigation. |
| Tablet-equivalent, 1600×2000 pixels, density 320 (800×1000 logical), dark | Materials, journal and profile retain bottom navigation above the Android tablet taskbar. Flat material rows remain readable and photo grids expand with available width. |
| Expanded landscape, 2560×1600 pixels, density 320 (1280×800 logical), dark | Feed, materials, profile and journal use the existing adaptive sidebar with the correct selected destination. The contained feed image and side actions remain reachable. The journal shows six lazy photo columns with compact metadata. |

Representative fixture evidence includes `feed-s22-light-final.png`,
`profile-s22-light.png`, `home-s22-light.png`, `feed-tab-retained-s22-light.png`,
`feed-undo-s22-light.png`, `feed-detail-s22-light.png`,
`feed-error-recovered-s22-dark.png`, `feed-hide-error-s22-dark.png`,
`feed-small-dark-scale2.png`, `home-search-keyboard-small-dark-scale2.png` and
`feed-landscape-menu-dark-scale2.png`, `home-search-keyboard-s22-light.png`,
`feed-s22-light-gesture-final.png`, `materials-tablet-dark-final.png` and
`home-wide-dark.png`. Captures made before the final fixture APK differ only in
avatar semantics; their visual appearance is unchanged.

PID-scoped Flutter logs for the isolated native fixture, before and after the
avatar correction, contain zero framework/E-flutter, RenderFlex/overflow,
unhandled future, failed asset or navigation-error patterns in these observed
phases. Counts are recorded in `runtime-patterns.json`. Handled synthetic error
states were tested deliberately and are not hidden or counted as successful data
loads. The final normal APK is restored at the ordinary build path after fixture
builds; its installed/build hash is verified independently above.
Cleanup verified that only the read-only QA emulator on 5560 exited. The ordinary
emulator on 5554 remains healthy on Home with the final normal APK; the ordinary
backend and development containers remain running. No account data was written
by this refinement's acceptance fixtures.

Physical Samsung hardware, TalkBack speech/focus behavior, hardware-keyboard
navigation, voice/photo permissions and complete two-client messaging delivery
remain separate acceptance checks. The underlying form/dialog keyboard behavior
has existing native acceptance above and automated enlarged-text/keyboard
coverage; every secondary editor was not manually repeated in this refinement.
Large Android viewports exercise adaptive layout, not support for iOS/web/desktop.

Documentation reviewed and updated with the implementation: `README.md`,
`UI_CONVENTIONS.md`, `DESIGN_SYSTEM.md`, this guide and the workspace
`ARCHITECTURE_REVIEW.md`. There is no cross-repository implementation follow-up or
approval pending for this presentation change.

## Cobalt/amber palette and Discover appearance — 2026-10-04

This refinement supersedes the previous pink/teal accents and the intentional
dark-only Discover presentation described above. White light-mode surfaces
(`#FFFFFF`) and existing near-black dark-mode surfaces (`#0C0C0E`) are unchanged.
Shared primary actions now use cobalt blue (`#2457D6` light, `#8AAEFF` dark), with
amber tertiary highlights and theme-specific readable container/foreground pairs.
Neutral secondary surfaces, layouts and existing navigation remain.

Discover's local `Theme(data: StudioTheme.dark())` wrapper caused it to stay dark
regardless of the user's appearance setting. That wrapper is removed: its app
bar, photo background, captions, rail, navigation, menus and async states now
inherit the active light/dark/system theme. Existing theme-derived media backing
continues protecting photograph/control contrast. No controller, route, API,
authentication, dependency, localization or backend-source change was needed.

Changed production files are `lib/ui/theme/studio_theme.dart` and
`lib/ui/pages/discover/discover_page.dart`. Updated tests are
`test/social_feed_layout_test.dart` and `test/studio_layout_test.dart`. One new
regression changes the active appearance twice while retaining the visible post;
existing viewport tests now expect the actual selected brightness. Theme tests
protect the exact white/near-black surfaces and validate at least 4.5:1 text
contrast for primary/tertiary actions and containers.

Completed bounded validation:

- Changed-file `dart format` and `git diff --check`: passed.
- Focused feed/theme/publication tests: all 43 passed, four seconds.
- `flutter test --no-pub --reporter expanded`: all 317 passed, 25 seconds.
- `flutter analyze --no-pub`: no issues, 39.4 seconds.
- Isolated fixture debug build: passed, 45.3 seconds.
- Regular `lib/main.dart` debug APK, API `http://10.0.2.2:8080`: passed, 28.4 seconds.

Native screenshots use the existing synthetic production-widget fixture on a
verified read-only/no-snapshot emulator 5560, with a 1080×2340/density-450 S22+
equivalent viewport and three-button navigation. The fixture uses `ThemeMode.system`;
switching Android night mode verifies real inherited light/dark presentation.
Inspected captures include populated Discover, Like (128→129) and its menu in
both themes, journal/Create in both themes, and Discover's light empty/error/
retry-recovered states. Bright synthetic photos retain readable caption/rail
foregrounds in both appearances. Fixture actions never delegate to the live
backend or create account data. Full physical Samsung/TalkBack acceptance and
every secondary screen were not repeated for this focused palette change.

Evidence is in ignored `build/palette-mobile-acceptance/`: `discover-light.png`,
`discover-liked-light.png`, `discover-menu-light.png`, `discover-dark.png`,
`discover-liked-dark.png`, `discover-menu-dark.png`, `journal-light.png`,
`journal-dark.png`, `discover-empty-light.png`, `discover-error-light.png` and
`discover-recovered-light.png`, with corresponding native hierarchies and logs.
Both process-scoped fixture logs contain zero framework, overflow, unhandled
exception or missing-asset matches; `runtime-patterns.json` records the counts.
Only verified emulator 5560 was stopped after QA.

The regular APK was installed with `adb install -r` on emulator 5554 after checking
the foreground page contained no unsaved form. Login, existing pieces/images and
the user's appearance preference remain. The ordinary journal and Discover now
both show the selected light appearance, without any preference writes during
QA. Screenshots `ordinary-home-current.png` and `ordinary-discover-current.png`
confirm this live behavior; the app is left on Home. Ordinary app-scoped runtime
checks also contain zero framework/overflow/unhandled/asset/disposed-state matches.
Installed package and ordinary build artifact share SHA-256
`0c91cdffd579c81f6f61ba0ae8b8768ddba628b7cb670f8ea1429a4fc0cc96bc`.
The API readiness endpoint returned `UP`; ordinary development services remain
running, without restart or migration.

Reviewed/updated documentation: `README.md`, `UI_CONVENTIONS.md`,
`DESIGN_SYSTEM.md`, this guide and the workspace `ARCHITECTURE_REVIEW.md`.
Backend runtime/status was inspected; prior backend documentation edits remain
untouched. No cross-repository follow-up or approval is pending.

## Publication requirements feedback - 2026-10-04

The owner publication card now displays checked/unmet requirements for setting
the stage to Finished and adding at least one photo. Publish is disabled until
both are satisfied. Requirements use current journal stage/image data, so changes
update the card immediately; the API's `eligible=false` default for an absent
publication does not incorrectly disable a ready piece. Unpublish remains
available for an existing episode that loses eligibility, while the moderation
lock remains enforced. Requirement rows expose checked semantics and wrap their
text. The photo-free Finished prompt now says "Add a photo to publish" and
confirms that the journal piece is already saved.

Changed implementation: `owner_publication_status_card.dart`,
`publication_prompt.dart`, and the card wiring in `ceramic_view_page.dart`.
English/Danish ARB sources and generated localization files were updated through
`flutter gen-l10n`. Coverage was updated in `owner_publication_status_test.dart`,
`publication_prompt_test.dart`, and `publication_prompt_integration_test.dart`.

Validation: formatting of the six affected Dart files passed; full
`flutter analyze --no-pub` found no issues. The focused `flutter test --no-pub`
run for owner publication status, prompts, prompt integration and localization
passed all 17 tests. Coverage includes every missing-requirement combination,
live readiness changes in English/Danish, absent-publication eligibility, and
unpublishing a hidden episode. `flutter build apk --debug --no-pub` passed.
The first sandboxed localization command could not access the Flutter SDK
launcher lock; it was stopped, and one retry with SDK cache access passed.
No generated source was edited manually.

The debug APK was installed with `adb install -r` on emulator 5554 after checking
the foreground hierarchy for an unsaved input form. Existing app data was
preserved. Native inspection verified the updated card; the screenshot shows a
Finished piece with no photo, its stage requirement checked, its photo requirement
unmet, and Publish disabled. Evidence is in ignored
`build/publish-requirements.png` and `build/publish-after-install.xml` (captured
at separate moments). APK SHA-256:
`551df2bfb5e9e14523f158189e7a74e35805cb83c710d37cc26d6020f0bd90ce`.
No publication, stage or photo changes were performed by this acceptance check.
Physical-device/TalkBack and every appearance/text-scale combination were not
repeated for this focused change.

Reviewed documentation: workspace `ARCHITECTURE_REVIEW.md`, `UI_CONVENTIONS.md`,
`DESIGN_SYSTEM.md`, backend publication documentation and both repository rules.
Updated documentation: client `README.md` and this guide. Backend publication
validation/DTOs were inspected and remain compatible; backend source and existing
data were not changed. No cross-repository follow-up or approval is pending.

## Ceramic audience text refinement - 2026-10-04

At the user's request, the Everyone explanation is omitted from the ceramic
detail publication card. Friends-only warnings remain applicable. Publication
requirements and authorization are unchanged; no API, localization generation,
dependency or backend update is needed. Updated files are
`owner_publication_status_card.dart`, its existing test, and `README.md` plus
this guide. Repository instructions and the existing publication documentation
were reviewed.

Formatting passed, full `flutter analyze --no-pub` found no issues, all six
`owner_publication_status_test.dart` tests passed, and
`flutter build apk --debug --no-pub` passed. The debug APK was reinstalled with
`adb install -r` on emulator 5554 after checking for focused input/keyboard activity,
preserving existing app data. Physical-device acceptance was not repeated.
The backend was not changed or revalidated for this presentation-only follow-up;
no cross-repository follow-up or approval is required.

## Finished stage without publication popup - 2026-10-04

Changing an existing ceramic's stage to Finished now saves directly and does not
open either the publication prompt or missing-photo dialog. Publishing remains
an explicit action in the detail card. The separate prompt after creating a new
Finished ceramic is retained. Removed the detail page's prompt import/helper and
simplified its stage callback. Updated the existing stage-transition integration
test to assert the saved Finished stage, no dialog, and no publication call.

Formatting passed; full `flutter analyze --no-pub` found no issues. The focused
`flutter test --no-pub` run for publication prompt integration, owner publication
status and publication prompts passed all 13 tests, including creation prompts
and publication readiness. `flutter build apk --debug --no-pub` passed, and the
updated APK was installed on emulator 5554 with `adb install -r`, preserving app
data after checking that no input field was focused or keyboard shown. No live
ceramic stage was changed for acceptance; the stage interaction is covered by the
widget integration test. Physical-device acceptance was not repeated.

Modified files: `ceramic_view_page.dart`,
`publication_prompt_integration_test.dart`, `README.md` and this guide.
Reviewed project instructions, `UI_CONVENTIONS.md`, `DESIGN_SYSTEM.md`,
workspace architecture/manual-testing notes and backend publication docs.
Historical dated acceptance notes describe their original runs; the current
workflow is documented in the README and this section. Backend source, API,
data and publication eligibility are unchanged. No cross-repository follow-up
or approval is pending.


## Home and Profile ceramic preview alignment - 2026-10-04

This section records the earlier Profile-based appearance. The user clarified
that the original Home cards should be retained; the corrected direction is
recorded in the following section.

Home and the private Profile now use the same ceramic thumbnail appearance:
cover-cropped photographs, a compact theme-derived title strip, matching loading/
failed-image placeholders, .72 portrait proportions and two-pixel gutters. Both
pages share a 900-logical-pixel grid content limit. The shared delegate retains
three columns on ordinary phones and adapts to narrower/expanded constraints.
Journal clay/stage/rating metadata remains in localized accessibility labels and
piece details; filtering, sorting, batch selection and detail routes are unchanged.
Public Profile tiles retain their optional clay subtitle, like count and publication
routes. The existing ceramic-sharing picker also uses the journal tile adapter.

Created `lib/ui/widgets/ceramic_preview_tile.dart` and
`test/ceramic_preview_tile_test.dart`. Updated the existing journal adapter,
`home_page.dart`, `profile_feature_page.dart`, `basic_profile_page.dart`,
`profile_widgets.dart` and `studio_layout_test.dart`. Reviewed repository
instructions, architecture notes, theme/controller/router/API/service/localization
boundaries, supported platforms and existing tests. Flutter 3.44.6 / Dart 3.12.2,
Material 3, AutoRoute, Cubit/ChangeNotifier, static repositories and the existing
Dio/service infrastructure are preserved. No generated code, dependencies,
backend source, contracts, authentication or persistent data changed. Updated
`README.md`, `UI_CONVENTIONS.md`, `DESIGN_SYSTEM.md`, workspace
`ARCHITECTURE_REVIEW.md` and this guide.

Bounded changed-file `dart format` passed. Full `flutter analyze --no-pub` found
no issues (36 seconds). Full `flutter test --no-pub` passed all 326 tests (46
seconds), including pixel comparisons between Home/Profile preview rendering
in both themes at normal and 2x text, failed-photo fallback, metadata semantics,
tap navigation and the existing journal/profile/sharing regression coverage.
The first targeted run exposed semantics-handle cleanup in the changed test;
cleanup was corrected without weakening the metadata or action assertions,
and the subsequent full suite passed.

Both isolated production-widget and ordinary `lib/main.dart` Android debug APK
builds passed. The fixture uses synthetic DTOs and loopback-hosted test images;
its adapter never forwards requests to the real backend. It was installed only
on verified read-only emulator 5560. Native Home/Profile screenshots were inspected
in light and dark mode at a Galaxy S22+ equivalent (1080x2340, density 450,
384 logical pixels wide) with three-button navigation. Matching tile bounds were
356x495 / 356x494 physical pixels: a one-pixel positioning-rounding difference.
Batch selection and cancellation were exercised without editing/deleting a piece.
A small 320x568 logical Android viewport at 2x text was inspected, including Home
search with keyboard open and the scrolled Profile grid. Evidence is retained in
ignored `build/preview-mobile-acceptance/`. Both grids were also visually checked
at 1280x800 logical pixels with the existing sidebar navigation. Fixture runtime
logs reported zero framework exceptions, overflows, unhandled exceptions or failed
assets across these configurations. Only the verified disposable emulator was
stopped after acceptance; the ordinary development emulator and backend remain up.

The ordinary debug APK uses `API_BASE_URL=http://10.0.2.2:8080` and was installed
with `adb install -r` on emulator 5554 after checking for active input/keyboard
and an unsaved form action. Existing login, account data and dark appearance were
preserved; startup Home and its runtime log were verified. Installed SHA256:
`96b2f0c69645db2be3b78fd06863f60ad3eead627225838bbd487c196d26b286`.
An ordinary Profile screenshot capture reached its bounded 40-second ADB timeout
while the isolated emulator was also running. After stopping the disposable
emulator, the single retry captured both ordinary pages and returned to Home.
A redundant subsequent Home capture also hit its 30-second ADB limit. The final
read-only verification reused the fresh successful Home screenshot and kept the
APK fingerprint, live-data/error-state, hierarchy and runtime-log checks.
The local backend readiness endpoint returned UP. Backend repository source was
not inspected or modified for this presentation-only task. No backend migration/restart,
backend validation or cross-repository source change was needed. Physical Samsung,
TalkBack and non-Android platforms were not tested in this focused follow-up;
Android remains the supported target. No cross-repository follow-up or approval
is pending.


## Restore Home previews and apply their style to Profile - 2026-10-04

The user clarified that Home's original previews were the preferred reference.
Restored their theme-surface metadata panel, bold title, optional clay, localized
stage and star/rating, two-pixel corners, tools placeholder and responsive card
sizing. Home's original column thresholds and 1100-pixel content limit are
retained in the shared delegate; card height grows with text scaling. Profile now
uses these shared cards and sizing rather than changing Home to title-only tiles.
Private Profile uses the existing journal adapter, stage list and clay list;
public Profile uses the existing authorized public DTO stage/rating fields and
preserves its like badge and publication route. No private fields are requested
for public profiles. Selection, filters, sorting, sharing and navigation are
unchanged. The existing ceramic-sharing picker regains the original Home style.

Modified `ceramic_preview_tile.dart`, `ceramic_journal_card.dart`, `home_page.dart`,
`profile_feature_page.dart`, `basic_profile_page.dart`,
`ceramic_preview_tile_test.dart` and `studio_layout_test.dart`. Updated README,
UI conventions, design-system guide, workspace architecture review and this
acceptance guide; no new source files, dependencies or generated code are needed.
Reviewed Flutter/Dart versions, existing component/controller/router/theme and
localization conventions, repository instructions and the matching backend
public-profile DTO/endpoint/service. Backend code, API contracts, authentication,
persistence and business controllers are unchanged; no migration or
cross-repository follow-up is required.

Changed-file formatting passed. The focused preview/layout run passed all 24
tests, including light/dark pixel parity at 1x and 2x text, visible clay/stage/
rating, accessible labels, failed-photo fallback, public likes and tap callbacks.
Full Flutter analysis found no issues (6.8 seconds).

Full `flutter test --no-pub` passed all 326 tests (70 seconds).

Both isolated production-widget and ordinary `lib/main.dart` debug APK builds
passed (30.5 and 16.7 seconds). Synthetic Home and Profile previews were visually
checked in light and dark mode on a Galaxy S22+ equivalent, 1080x2340 at density
450, with three-button navigation. Matching card bounds were 356x548 on Home
and 356x547 on Profile, differing only through physical-pixel position rounding.
Small Android, 320x568 logical pixels, was checked at 2x text, including the
scrolled Profile grid; both use two columns and preserve stage/rating. Native
screenshots and UI hierarchies are in ignored
`build/home-preview-mobile-acceptance/`. An unrelated Android Chrome crash dialog
covered the fixture during its initial 20-second wait; it was dismissed on the
read-only test emulator and the visual check then succeeded. The fixture's
synthetic DTOs/loopback images never access the real backend or user data.

Both pages were also visually checked at 1280x800 logical pixels using the
existing sidebar navigation. The fixture runtime log reported zero framework
exceptions, layout overflows, unhandled exceptions or failed assets across these
configurations. Only the verified read-only emulator was stopped after QA.
Physical Samsung/TalkBack checks were not repeated for this focused correction;
Android remains the supported platform. No approval is pending.

The corrected ordinary APK was installed with `adb install -r` on emulator 5554
after checking for focused inputs, a keyboard and an unsaved form action. The
following force-stop hit its 30-second ADB limit; the installed APK fingerprint
and live process were verified instead, and foreground launch succeeded. The
app retained its Profile route, so the first Home-only wait expired; navigating
to Home resolved that check. Fresh Home and Profile screenshots were captured
through Android screenshot files, avoiding the earlier intermittent exec-out
stream. Both actual pages display the restored title/clay/stage/rating panels;
the app was returned to Home. Existing account data, login and dark appearance
were preserved. Final verification confirmed live journal data, the APK identity,
Home visibility and zero framework/overflow/unhandled/asset/disposed-state errors.
Installed SHA256:
`362f6ce00386d8bdedb555d66e066a2ef9b1fcc69b3670b4ea9f8046d64d29a5`.
The app uses `API_BASE_URL=http://10.0.2.2:8080`; backend readiness remained UP.
The ordinary emulator/backend are left running for testing. No persistent data
was cleared, no backend source changed and no approval/follow-up remains.


## Ceramic preview placeholder centering - 2026-10-04

The no-picture icon was centered over the full card, including the bottom
metadata panel, which made it appear low in the visible image area. The shared
preview now lays out the caption at its natural height and centers missing,
loading and failed-image placeholders in the remaining photo area. Caption
height responds to actual metadata and text scaling; no fixed offsets or guessed
text heights are used. Loaded photos retain their previous full-card cover crop
and caption backing colors. Home, private/public Profile and the ceramic-sharing
picker inherit the same fix without changing their data, routes or actions.

Modified only `lib/ui/widgets/ceramic_preview_tile.dart` and
`test/ceramic_preview_tile_test.dart` in source/tests. Regression checks measure
both coordinates against the visible photo area's center for metadata and
title-only captions, including null/failed photos, light/dark appearance and
1x/2x text; existing visual parity and tap/like/semantics checks are retained.
Reviewed repository instructions, architecture notes, Flutter 3.44.6 / Dart
3.12.2, existing theme/widgets/controllers/router/services/localization/testing
and Android support. Updated README, design-system guide, UI conventions and
this guide. No generated files, dependencies, API contracts, state/navigation
frameworks, business controllers or backend code need changes; the backend
repository was not inspected or modified for this layout-only correction.

Bounded changed-file formatting passed. The focused preview/layout run passed
26 tests; full Flutter analysis found no issues.

The final `flutter test --no-pub` run passed all 328 tests in 43 seconds;
`flutter analyze --no-pub` passed in 7.2 seconds. The ordinary debug APK built
successfully with the existing `lib/main.dart` entry point and local Android
API bridge. Installed with `adb install -r`, preserving login, account data and
appearance preferences. Installed SHA256:
`be67f7aad6b83eeab94e80ced0d5e30ed6296f0ce823cd78b43f6de6a9d6d246`.

Native Home and Profile screenshots confirm that the tools icon is centered in
the gray photo area above the title/clay/stage/rating panel. The existing real
photo retains its crop and translucent caption. Current dark/gesture-navigation
appearance and two existing ceramic entries were preserved. Screenshots, test
output, APK metadata and runtime results are retained in the ignored
`build/centered-preview-mobile-acceptance/` directory. Two initial accessibility
inspection attempts failed while the foreground app was blank; a bounded local
app restart and Flutter Inspector first-frame/widget-readiness checks preceded
successful screenshots and accessibility verification. No further code changes
were needed. An optional scripted pixel comparison could not run because Pillow
is unavailable; visual review and existing widget pixel-parity tests passed.

Final installed-APK verification passed and reported zero framework exceptions,
layout overflows, unhandled exceptions, failed assets or disposed-state errors.
The app is left on Home, and local backend readiness is UP at port 8080.
Physical-device, TalkBack, keyboard, three-button-navigation and native light-mode
checks were not repeated for this focused alignment fix; widget checks cover
both themes and increased text scaling. Android remains the supported platform.
No backend source, shared API or persistent data was changed, no cross-repository
follow-up is required and no approval is pending.
