# Timetable Feature Specification & Guide

This document describes the timetable parsing, local storage, UI view modes, and multi-user comparison architecture for Project Zapp.

## 1. Overview and Scope

The timetable module provides:
- Registration table text parser supporting VTOP copy-paste format.
- Multi-day weekly schedule timeline and daily slot display.
- Master Timetable Matrix view displaying all 12 theory and lab slot columns for Monday through Friday.
- Admin multi-select workflow to compare schedules and generate combined availability matrices.
- Local-first persistence using SQLite (`sqflite`) with offline fallback.

## 2. Supported VTOP Timetable Paste Format

The parser accepts tabular copy-paste data separated by tabs, pipes (`|`), or two or more consecutive spaces.

Recognized columns:
- `Course Code` (e.g. `BMAT101L`, `BCSE102P`)
- `Course Title` / `Course Name` (e.g. `Calculus`, `Programming Lab`)
- `Slot` / `Slot - Venue` (e.g. `A1+TA1 - SJT101`, `L31+L32 - AB3-405`)
- `Faculty` / `Faculty Name` (e.g. `Dr Ada Lovelace`)
- `Venue` / `Room` (when separated from slot)

Example input:
```text
Course Code | Course Title | Slot - Venue | Faculty
BMAT101L | Calculus | A1+TA1 - SJT101 | Dr Ada
BCSE102P | Programming Lab | L31+L32 - AB3-405 | Dr Grace
```

Validation rules:
- Combined slot expressions (e.g. `A1+TA1+TAA1`) expand into their constituent weekly periods according to the Vellore weekday slot pattern (`lib/features/timetable/slot_pattern.dart`).
- Identical rows are deduplicated.
- Unknown slot codes or missing metadata reject the upload without accepting a partial timetable.
- Failed imports leave existing saved schedules intact.

## 3. Slot Pattern System

The Vellore weekday pattern covers:
- Theory slots: 12 hourly periods daily (08:00 to 19:25) across Monday–Friday.
- Lab slots: 60 distinct lab periods (`L1` to `L60`), each mapped to a specific day and time block.
- Days: Monday through Friday active; Saturday and Sunday available as selectable empty periods.

Timetable pattern mappings reside in `lib/features/timetable/slot_pattern.dart`.

## 4. UI Modes & Views

### 4.1 Student View
- **My Schedule**: Daily timeline selector (Monday–Friday) showing scheduled classes with course title, room, slot code, and timings.
- **Groups**: View Study Squad availability, current squad code, and comparison matrix.

### 4.2 Administrator View
- **Schedule Tab**: Displays individual student cards. Tapping any card opens their schedule with a toggle between:
  - **Schedule**: Standard daily class list.
  - **Matrix View**: Master Timetable Matrix displaying the full 12-slot horizontal grid with active slots highlighted in green (`#E8F7EC`).
- **Multi-Selection Mode**: Long-press any student card to enter selection mode. Selecting two or more students displays **"View Combined Timetable"**, generating a real-time matrix comparing free and busy slots across all selected members.
- **Groups Tab**: Retains existing Study Squad management and squad code display.

## 5. Storage Architecture

Timetable entries are persisted atomically:
- Local database: `zapp_timetables.db` managed via `lib/features/timetable/timetable_store.dart`.
- Schema: Snapshot versioning per authenticated `ownerId`, isolating user schedules and preventing cross-user data leaks.
- Cloud sync: Synchronized via `lib/core/api_client.dart` when a Cloudflare Worker backend is connected.

## 6. Verification and Testing

Execute the following commands from the repository root:

```sh
flutter analyze
flutter test lib/features/timetable/tests test
```

All 16 unit and widget test suites must pass before submitting a pull request.
