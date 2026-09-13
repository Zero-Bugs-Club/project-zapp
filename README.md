# Project Zapp

Flutter application for Android and iOS with two primary functions: geo-tagged photo capture and VIT timetable matching.

## 1. Overview

The application contains two tabs:

1. Camera. Captures a photograph, records the device geolocation and timestamp, and stores the record locally on the device. No cloud upload is performed.
2. Timetable. Content is determined by the authenticated role:
   - Standard user: seven-day view of their own parsed timetable.
   - Administrator: seven-day grid of common free slots aggregated across all users.

Authentication precedes navigation. It has no tab. The same login screen serves standard users and administrators; the stored role controls the Timetable tab content.

## 2. Modules

| Module | Directory | 
|---|---|
| GPS camera | `lib/features/gps_camera/` | 
| Timetable (user and admin views) | `lib/features/timetable/` |
| Authentication | `lib/features/auth/` | 

Shared code resides in `lib/core/` (models, API client, constants, theme, VIT slot grid). Modifications to shared code require prior agreement with the project lead.

## 3. Technology

- Client: Flutter (Dart), Riverpod for state management.
- Local storage: sqflite for GPS photo metadata.
- Backend: Cloudflare Workers (API layer) and Cloudflare D1 (database). No Firebase is used.
- Authentication: credentials verified by the Worker against salted hashes in D1; the Worker issues a JSON Web Token that the client presents on subsequent requests.

## 4. Repository Layout

```text
lib/
  main.dart                  Application entry point, authentication gate, tab navigation
  core/
    api_client.dart          login(), saveTimetable(), getFreeSlots() — stubs with contracts
    constants.dart           API base URL, database file name
    theme.dart               Shared Material 3 theme
    vit_slot_grid.dart       Static VIT slot code to day/time mapping
    models/
      user.dart              AppUser, UserRole
      timetable_slot.dart    TimetableSlot
  features/
    gps_camera/              Camera screen, local photo store
    timetable/               Parser, user view, admin free-slot view
    auth/                    Login screen, authentication state
```

Refer to `CONTRIBUTING.md` for environment setup and build instructions.
