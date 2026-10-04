# Keramik social UI

The October 2026 refinement follows the user's TikTok reference: white/near-black
surfaces, cobalt-blue primary actions, warm amber highlights, bold compact
typography, flat rows and tight photo grids. Material 3 remains the component
base. It extends the existing
Flutter architecture and retains current product flows. Android remains the
supported target; wider layouts do not add platform support.

## Shared components

`lib/ui/theme/studio_theme.dart` supplies the light/dark palettes and defaults for
cards, buttons, fields, chips, app bars, dialogs, sheets, menus, snackbars and
lists. Buttons/fields use four-pixel corners; ornamental cards and oversized
icon headings are removed. `main.dart` selects these themes through the existing settings controller
and preserves light/dark/system behavior. Feature widgets read the active
`ColorScheme`. Avatar colors and media overlays retain their functional meanings.

`lib/ui/widgets/v2/studio_widgets.dart` provides `StudioSpacing`, `StudioContent`,
`StudioSurface`, `StudioPageHeader`, `StudioSectionHeading`, `StudioFeatureTile`,
`StudioEmptyState`, `StudioMediaOverlay` and the decorative `StudioBrandMark`. Use these for repeated
page/state/navigation treatments. `StudioSurface` provides padding without a card.
Content is centered at up to 1100 logical
pixels; forms use a 760-pixel reading limit. `StudioContent` does not add scrolling:
place scroll views in a bounded scaffold body or `Expanded` parent.

The existing `v2` fields stay the reusable input controls. `DropdownWidget.label`
is a compatible adapter for legacy callers. `EntryPage` retains its Save/Edit/
Delete behavior while `EntrySection` supplies shared section spacing.
`EntryValue(selectable: true)` preserves copyable template details.

## Responsive navigation and accessibility

`StudioScaffold` in `navigation_widget.dart` preserves all five root destinations
and their existing AutoRoute replacement behavior. Compact layouts have labeled,
focusable bottom destinations with height that grows with text. When full labels
need more width, the active destination retains its full label and other icons
retain tooltips and explicit semantic names, with at least 48-pixel targets.
Extremely narrow/enlarged layouts scroll horizontally and reveal the selected
destination. Text is never scaled down to force a fit. At 840 logical
pixels it uses a scrollable 220-pixel sidebar. The app bar owns the status-bar
inset; navigation owns its bottom system inset outside destination content;
page bodies own content insets. Secondary pages retain their existing routes.

Journal/profile grids, inboxes and material/notebook lists build records lazily.
Home is the visual reference for ceramic previews. Home and Profile use
`CeramicPreviewTile` and `CeramicPreviewGrid` from
`lib/ui/widgets/ceramic_preview_tile.dart`: cover-cropped images, two-pixel
corners/gutters, a theme-surface metadata panel, bold title, optional clay subtitle,
and localized stage plus star/rating. Loading/failed images use the same tools
placeholder, centered within the visible photo area above the caption. The
caption's natural layout height determines the remaining area; no guessed text
height or fixed icon offset is used. Loaded photos retain their full-card cover
crop underneath the caption. Both grids share the existing 1100-pixel content limit and Home's
responsive column thresholds; tile height grows with system text scaling.
Titles ellipsize visually and remain fully accessible. `CeramicJournalCard`
adapts journal data on Home, private Profile and the ceramic-sharing picker;
all use the same metadata and detail navigation. Public profiles use authorized
public card data, with the same stage/rating panel and their existing optional
like badges. Publication visibility and private/public data boundaries are unchanged.
Forms and option sheets scroll with the keyboard open. Settings values sit below
labels. Core buttons and rating/stage choices have minimum 48-pixel tap targets.
Headings, navigation selection and ratings have meaningful semantics. Images keep
their layout while loading/failing. Empty/error components scroll when bounded
height cannot fit their content. Set `StudioEmptyState(scrollable: false)`
when a parent sliver owns scrolling and needs intrinsic sizing.

Existing chat timeline, media controls, request rules and gestures are preserved.
The conversation body also protects read-only footers from Android navigation.
Loading/error/empty states retain existing data where the controller supports it.

## Immersive Discover

Discover uses a vertically paged image feed with a compact For You/Latest tab
header. Each tab retains its own page position. Discover inherits the app's
selected light/dark/system appearance, including its header, image background,
caption/action overlays, navigation and menus. There is no page-specific dark
theme override. Photos use `BoxFit.contain` so whole ceramic objects
remain visible. Creator, Like, Share, Information and More use a right-side rail;
captions stay at the bottom. Persistent theme-derived backing protects contrast
over bright images. Both overlays scroll when height/text scaling requires it.

The existing publication IDs preserve visible identity across updates. Reaching
the final loading page requests more data; failed pagination requires Retry.
Failed refresh keeps the current image and exposes a retry banner. Hide/Undo
reconciles the page index. Creator, detail, report and conversation sharing retain
their existing behavior. The image feed uses the existing data/API; it adds no
video, comment or follower features. The visual direction interprets TikTok's
[For You discovery model](https://newsroom.tiktok.com/learn-why-a-video-is-recommended-for-you)
for the app's current pottery publications.
The creator avatar has one actionable username tooltip and excludes decorative
initials from its semantics, avoiding duplicate screen-reader focus targets.

## Scope and compatibility

The pass covers login, journal/piece forms/details, templates/batches, materials/
clays/glazes/notebooks/inventory, Discover/publications, chats/request/group/share/
report flows, profile/friends/search/edit, account/privacy/membership settings,
analytics and image viewing. The shared theme/entry components also restyle
related editors and dialogs.

Repositories, DTOs, API/session behavior, routing, persistence, entitlement and
business controllers are unchanged. The only non-widget application change is
`main.dart` selecting the extracted theme. English/Danish catalogs add neutral
`operationFailed` and `pieceSavedPublicationUnconfirmed` copy; generated
localizations are rebuilt. No dependencies, backend implementation or migrations
are required.

Focused fixes prevent duplicate piece/clay creation and leaving during Save,
prefill the saved supplier, stop automatic Discover retries after pagination
or refresh failure, handle hide/Undo/report failures, and replace raw technical
errors with localized feedback in updated flows. Existing explicit/immediate save semantics
remain intact. Optional publication failure returns the successfully saved piece
to the journal with clear feedback; it never offers another creation for that
successful save. The publication decision keeps Save blocked without an
indeterminate spinner. Detail mutations are disabled until their data loads,
and initial retry retains the route seed. An empty journal reserves the main
Create action for its empty state. Account password/export/deletion failures use
localized feedback rather than server exception text. Group-member retries reset
loading/error state and build potentially large friend lists lazily.

## Changed areas

New files include reusable profile identity/stat/photo widgets and
`test/social_feed_layout_test.dart`; prior files are the theme, shared studio widgets, this guide and layout/control/
detail-state tests. Modified files are `main.dart`, English/Danish catalogs and
generated localizations, shared v2 field/navigation/image/rating/stage/tag/entry
components, the journal card, pages in the existing home/materials/Discover/chat/
profile/settings/analytics/image/login modules, focused existing tests,
`README.md`, `UI_CONVENTIONS.md` and `MOBILE_TESTING.md`. The workspace architecture
review records the preserved system boundaries.

## Validation

Run `flutter analyze --no-pub`, `flutter test --no-pub` and an Android debug build.
The palette/appearance refinement passes all 317 tests and full analysis. The ordinary
API-8080 Android debug APK is installed on the development emulator with its
existing session and data retained. Native screenshots and isolated feed-state
checks for this refinement are recorded in the latest section of the mobile guide.
`test/studio_layout_test.dart` covers the production theme/contrast, widths
320/384/800/1280, enlarged text, system navigation, keyboard forms, retry/empty
states, existing routes and compact cards. Actual installed-device evidence and
remaining acceptance are recorded in [MOBILE_TESTING.md](MOBILE_TESTING.md).
