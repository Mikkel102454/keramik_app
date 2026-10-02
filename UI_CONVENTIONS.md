# Shared UI and entry-page conventions

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
