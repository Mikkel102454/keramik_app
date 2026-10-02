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
