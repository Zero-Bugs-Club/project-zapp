# Timetable feature — Issue #2

All source, tests and documentation for this change live in `lib/features/timetable/`.
Shared models, authentication, navigation, dependencies and platform configuration are unchanged.

## Scope

Issue #2: paste a course-registration table, inspect a preview, atomically replace
one authenticated user's local SQLite snapshot, restore it on opening the tab,
show seven vertical day tabs (selected day green), class-detail bottom sheets,
and an administrator's VTOP-style theory/lab grid from the same local upload.

The Figma file currently contains Groups home, Group availability, Create group,
and Add people/group settings. Its purple (`#4A4FB8`), pale background
(`#F6F7FD`), white rounded cards and typography guide this feature's styling.
Group invitations, sharing, the extra Groups navigation destination and
multi-user free/busy comparisons are outside Issue #2. Its explicit vertical
seven-day selector and green selection take precedence over Figma's horizontal
five-day group selector. No Figma screenshot is embedded as application UI.

## Supported paste

Copy complete rows with tab, pipe or two-or-more-space column separators.
Include headers when possible. Recognized columns: Course Code; Course Title /
Course Name; Slot / Slots / Slot - Venue; Faculty / Faculty Name; Venue / Room.
Column order can vary when headers are present. Without headings, standard
registration rows must contain a course code followed by its title, a combined
slot/venue cell and the faculty name immediately after that cell.

```text
Course Code | Course Title | Slot - Venue | Faculty
BMAT101L | Calculus | A1+TA1 - SJT101 | Dr Ada
BCSE102P | Programming Lab | L31+L32 - AB3-405 | Dr Grace
```

This is a synthetic fixture, not a real student's registration record.
One slot can create multiple weekly periods. Identical rows are deduplicated;
unknown slots, missing details and unreadable rows prevent saving. A failed
save leaves the prior snapshot intact. Previewing never writes to disk.
Raw pasted text is not stored or uploaded. Nothing calls the stub Worker API.

## Slot-pattern research and limits

VIT's official FFCS explanation confirms that courses, professors and class
timings are independently chosen: https://vit.ac.in/academics/ffcs.
The public VTOP course offering document shows the course/venue/slot/faculty
columns and combined slot expressions:
https://vtop.vit.ac.in/vtop/downloadSpotLightViewFile/396?x=Tue%2C+27+Jul+2021+13%3A40%3A51+GMT.

The feature-owned pattern comes from the timetable published by FFCS On The Go:
https://ffcsonthego.srev.in/. It expands repeated theory slots and all L1–L60
periods, using that site's separate theory and lab timings. It is explicitly
labelled `vellore-weekday-v1`; it is NOT a verified official 2026 campus-wide
mapping. Saturday and Sunday are selectable empty days in this pattern.
Other campuses, weekend classes and revised patterns need their own verified
mapping. Unsupported codes are blocked rather than silently dropped. Confirm
this pattern against a real target-campus VTOP timetable before release.
The incomplete representative `lib/core/vit_slot_grid.dart` is left untouched
because shared-code changes require lead agreement.

## Issue #3 handoff

`TimetableEntry` extends the existing shared `TimetableSlot` without changing it.
It adds courseCode, teacher and venue, plus JSON conversion. The SQLite database
`zapp_timetables.db` contains one atomic snapshot per authenticated owner ID.
Snapshots include schemaVersion=1, slotPattern and normalized entries with day
(1=Monday), slotCode, course, courseCode, teacher, venue, startTime and endTime.
Times use local campus HH:mm; `startMinute`/`endMinute` are available for interval
comparison. A code alone is not an occurrence identifier.

Issue #3 should agree the term/timezone/owner authorization contract, adapt these
entries to its Worker/D1 schema, then compare at least two complete uploads.
Owner IDs must come from authenticated server identity. A person with no
uploaded timetable is unknown, not automatically free. The server should use
half-open interval overlap (`a.start < b.end && a.end > b.start`).
UI selection, SQLite row keys, parsing diagnostics and raw pasted text stay local.
This handoff is a proposal; it does not modify or claim agreement on core APIs.

## Verification

Run from the repository root:

```powershell
flutter --no-version-check analyze
flutter --no-version-check test lib/features/timetable/tests test
flutter --no-version-check build apk --debug --no-pub
```

The version-check flag avoids an SDK-cache permission failure on this machine;
it does not disable analysis or tests. Feature tests remain inside the assigned
folder, so the explicit feature test path is necessary in addition to `test/`.
Storage tests exercise the real sqflite Dart transaction/SQL layer with a mocked
platform channel. They cover serialization, reopening, replacement, owner
isolation and rollback, but do not replace native-device SQLite verification.
Widget tests cover preview/save/error flows, role views, seven days, details,
and 320px width with enlarged text.

Verification on October 10, 2026:
- Analysis: no issues.
- Functional tests: 13 passed; the optional preview exporter is skipped unless enabled.
- Preview exporter: passed separately; upload, student, details and grid renders inspected.
- Android debug build: failed first on existing Gradle transform metadata/lock corruption.
  Retrying with `GRADLE_USER_HOME` pointing to a temporary isolated cache failed
  during Android project configuration with `java.util.concurrent.TimeoutException`
  and an AGP `compileSdk` diagnostic. `android/app/build.gradle.kts` already contains
  `compileSdk = flutter.compileSdkVersion`; the diagnostic does not establish that
  the setting is actually absent. No platform/configuration source was edited.
  Android build verification remains unresolved; do not report it as passing.

Optional rendered previews (uses the installed SDK's fonts):

```powershell
flutter --no-version-check test --no-pub lib/features/timetable/tests/timetable_preview_test.dart --dart-define=TIMETABLE_PREVIEW_DIR=C:/tmp/zapp-previews
```

The existing authentication stub returns fixed IDs (`user-1`/`admin-1`), so
different typed usernames do not yet represent distinct authenticated owners.
Storage is keyed by the provided owner ID; real unique identities belong to the
authentication/backend work.

iOS compilation requires a Mac/Xcode (see CONTRIBUTING.md). This Windows
checkout cannot establish an iOS build pass. No cloud CI config outside this
feature directory is added.
