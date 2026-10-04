# Shared UI and entry-page conventions

## Studio design system

The whole-app social presentation uses `StudioTheme` and shared `Studio*` components
alongside this `v2` library. Follow [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for theme
ownership, adaptive navigation, bounded forms, flat surfaces and safe areas.
Keep business operations in the existing layers. `EntryPage` retains its actions
and save rules while `EntrySection` owns shared section spacing. `StudioSurface`
adds consistent padding without a decorative card. `StudioMediaOverlay` protects
caption/control contrast over photographs. Keep the same component names rather
than duplicating a second set for the new visual direction.
All pages, including Discover, inherit the selected light/dark/system theme.
Keep the white/near-black surfaces and use the shared cobalt/amber ColorScheme
for accents; do not add feature-specific forced appearance overrides.
Use `CeramicPreviewTile` for ceramic photo previews and
`CeramicPreviewGrid.delegate` for journal/profile grids. Keep crop, caption,
placeholder, proportions and gutters in that shared widget rather than creating
page-local card trees. Home's original metadata-panel style is the reference:
bold title, optional clay, localized stage and star/rating, with a theme-surface
background. Journal adapters retain this information in accessible labels too.
Pass the active text scaler to the grid delegate so card height adapts. Public
profile tiles use their existing authorized stage/rating data and like badges.
Center empty/loading/failed-photo icons in the remaining photo area after the
caption is laid out; metadata and text scaling must not shift them off center.

Use the existing UI library at `lib/ui/widgets/v2/ui_library.dart`. Extend a
shared component when a supported option is missing. Pages pass labels, values,
limits, validators and callbacks; they do not recreate borders, fill colors,
padding or field typography for each input.

## Fields

- `TextFieldWidget` supports labels/placeholders, a caller-owned controller or
  an initial value, length limits, multiline input, keyboard/input formatters,
  units, error text, validation and asynchronous accept/revert callbacks.
- `SelectFieldWidget<T>` provides controlled selection, including nullable
  “not set” choices. `DropdownWidget` remains the compatible asynchronous
  accept/revert wrapper used by older pages.
- `FormFieldStyle` owns field radius, colors, padding, focus/error borders and
  typography. The app theme uses the same decoration theme so remaining native
  Material inputs inherit the common appearance.
- Use `label` for a persistent label above an input. Use `placeholder` for a
  hint inside it. Do not repeat a separate page-local label when the helper
  already supplies one. Labels may wrap; entered values must stay unobscured.
  A field's accessible name remains present after typing. Use `semanticsLabel`
  when a section heading already supplies the visible label, such as result
  notes; this avoids repeating that heading inside the field.
- Keep domain rules in the existing validation/controller layer. Limits remain
  those of each API: glaze titles are 255 characters, notebook names 100, for
  example. Visual consistency does not mean making those rules identical.
- A supplied controller belongs to the page and must be disposed by the page.
  A helper-created controller belongs to the helper. Choose one, not both.

```dart
TextFieldWidget(
  controller: titleController,
  label: context.l10n.title,
  maxLength: 255,
  validator: (value, context) =>
      value == null || value.trim().isEmpty
          ? context.l10n.requiredField
          : null,
)

SelectFieldWidget<int>(
  label: context.l10n.clay,
  value: selectedClayId,
  items: clayChoices,
  onChanged: (value) => setState(() => selectedClayId = value),
)
```

## Chat

Use `MessageComposer` from the `v2` library for chat input. The page owns and
disposes its draft controller, clears it only after successful sending, and
supplies availability-gated callbacks. The shared bar listens to controller
changes (including programmatic emoji insertion/clearing), keeps multiline input
and a 2,000-code-point limit, and prevents draft edits during sending without
closing the keyboard. Empty drafts show media controls; any text swaps those
controls for Send while retaining emoji and ceramic sharing. Disable Send for
trimmed-empty text. Nullable media/share callbacks retain request/server gates.
An available camera shortcut sits beside the empty bar and opens the camera
directly; the photo icon opens the native photo grid directly, followed by a
single-image preview and Cancel/Send. Do not add a source-choice screen before
these actions or broaden gallery permissions to imitate a platform-specific grid.

`MessageComposer` keeps its pointer listener mounted when a voice bar replaces
the text input. Hold starts recording; pointer up sends; an 80-pixel left drag
arms cancellation and animates the trash lid without stopping capture. Release
while armed discards; moving back disarms. A 70-pixel upward drag locks. An armed
recording also discards at the one-minute limit. Pointer cancellation discards. Avoid a
microphone Tooltip long-press recognizer competing with recording; provide the
accessible name and gesture hint through semantics. Tap/keyboard activation is a
locked-recording alternative. `ChatVoiceDraftController` owns permission/start/
stop/upload coordination, timers and app-cache cleanup, with a stable UUID per
recording. `ChatVoiceComposer` displays time, cancel/lock guidance, locked Stop,
preview playback and Send/retry. Record for at most one minute. Locked Stop and
the held/locked time limit send automatically while foregrounded and allowed.
Interruptions stop to preview; failed uploads retain a retry preview and UUID.
Cancellation during asynchronous
startup/Stop must suppress upload. Preserve failed drafts, prevent duplicate
uploads and stop microphone capture when the chat is disposed/backgrounded.

Direct/group message rows share fully rounded bubbles and theme colors. Every
received non-system message has a bottom-aligned `ProfileAvatar`; own messages
and system events have none. Direct avatars use conversation profile data,
group avatars use message sender data. Keep group names linked to fresh profiles,
and route avatars through the same UUID fetch and refresh-on-return behavior.
The direct header is one accessible, keyboard-operable profile target covering
the avatar, name, gap and remaining title width; suppress splash and state
highlights. Received-avatar and voice-playback targets also suppress pressed
highlights. Group headers retain their existing actions.

Photos own their rounded clip without surrounding bubble color/padding. Preserve
the full aspect ratio with available-width/250-pixel and 340-pixel-height bounds;
loading/error previews retain the same geometry. Voice pills own their surface,
circular playback control, decorative (not recorded waveform) bars and `m:ss`
duration, with localized playback/retry semantics. Match a one-line text bubble's
height (the scaled text line plus 20 pixels), including loading/retry states.
Preserve reporting gestures,
card navigation and loading/retry feedback. Images and interrupted/failed voice
drafts use preview/Send; held recordings use release-to-send.

Keep local outgoing previews in `ConversationPageController.localSends`, separate
from acknowledged server history. Show them immediately with Sending, then either
replace with the receipt or retain Not sent in the theme's error color, neutral
localized feedback and Retry. Match `reference/Chat/fail.jpg`'s failure placement;
do not invent its moderation restriction. Preserve UUIDs and text/voice drafts.
Photo Send transfers its private file to the local send and closes the preview;
retain it on failure, deleting it after acknowledgment or chat disposal. Await
an in-flight upload before disposal cleanup. Voice files remain recording-owned;
discard removes their local row. Local cards cannot open server detail routes.
Never use local IDs for read markers, pagination or reporting. This state is
session-only, with no background/durable send queue. Unknown delivery after a
lost response is resolved by explicit idempotent retry.

Chat history uses a reversed `ListView.builder`: index zero is the newest row
and scroll position zero is the bottom on the first frame. Do not render the top
and jump afterward or build older messages to estimate total height. Fetch only
the latest 50 messages, then load a single cursor page when scrolling within 200
pixels of the older edge; keep an explicit Load earlier action. Ignore duplicate
in-flight triggers, stop at a null cursor, and require explicit retry after failure.
Merge by server ID, retaining older loaded history/cursors during latest-page
refresh. Build media only with lazy rows near the viewport. Stable row keys retain
attachment state; anchor reading position to message content, excluding date
separators that can move during pagination.

Local enqueue, acknowledgment and failure details advance the send revision and
animate to scroll position zero after layout. Initial loading and ordinary incoming
reconciliation do not animate to the bottom. Preserve a visible message anchor
when ordinary refreshes arrive while reading older history. Check compact widths,
large text, keyboard, locales and both themes.

## Similar functionality uses similar pages

Glaze entries, glaze combinations and test tiles share the create → open →
read → edit → save workflow. Use `EntryPage`, `EntrySection` and `EntryValue`
for this family. Different domain content is expected; different navigation,
field treatment and action placement need a functional reason.

| State | Common presentation and behavior |
| --- | --- |
| Create/edit | Action title, Save in the app bar, Information first, labeled inputs, then domain sections |
| View | Record name in the app bar, Edit followed by Delete, read-only labeled values and matching section order |
| Save pending | Progress indicator, disabled mutations, prevent leaving until the request finishes |
| Save failed | Localized inline error, keep every draft value, allow deliberate retry |
| Back with edits | Shared discard confirmation; Cancel keeps the complete draft |
| Delete | Confirmation before writing, preserve existing ownership/conflict/in-use rules |
| Refresh | Pull to refresh on details, safe inline failure with Retry |

`EntryPage` owns 16-pixel page padding, safe-area handling, scrolling, app-bar
action order, progress and error placement. `EntrySection` owns section headings
and spacing. `EntryValue` uses the common label/surface treatment while remaining
read-only, rather than presenting an editable control on a detail page.

Glaze details now open a separate editor and save the title explicitly; typing
does not send a request. Combinations/test tiles preserve their existing atomic
versioned save and snapshot behavior. Feature-specific actions such as recipe
application and tile photos follow the common information/domain sections.
Do not add inactive Share or other placeholder controls to imitate another page.

The account profile editor reuses `TextFieldWidget`, the shared discard dialog,
and `EntryValue` for the public account ID. Its app-bar Save follows the same
pending/failure/draft rules. Photos remain immediate mutations, so the editor
keeps a separate text draft across photo refreshes instead of replacing the
draft with each fetched account. Name/username limits count trimmed Unicode
code points in the profile controller; do not substitute a field's grapheme
length limit. Native profile layout and session checks are recorded in
[MOBILE_TESTING.md](MOBILE_TESTING.md).

## Scope and review

Improve the shared primitive first, then adopt it in the affected page family.
Do not rewrite every field in the app as part of a small UI change. Older clay,
piece and settings flows retain their existing save semantics until deliberately
aligned; the common field theme/helpers already give them matching surfaces.
New entry flows should use this convention, and modifications to existing flows
should move toward it without unrelated behavior changes.

Compare related pages side by side before considering a UI change finished.
Check create/view/edit, light/dark, English/Danish, compact width, enlarged text,
keyboard/scrolling, long labels, pending/failed saves and draft cancellation.
Follow [MOBILE_TESTING.md](MOBILE_TESTING.md) for installed Android checks and
record actual results separately from widget tests and builds.
