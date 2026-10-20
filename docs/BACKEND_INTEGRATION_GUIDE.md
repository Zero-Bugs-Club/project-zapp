# Backend Integration Guide

This document describes the Cloudflare Workers, Cloudflare D1 database, and API integration specifications for Project Zapp.

## 1. System Architecture

```
Flutter Client (Android / iOS / Web)
    │
    ├── Local Storage (sqflite / in-memory fallback)
    │
    └── Network Layer (lib/core/api_client.dart)
            │
            ▼ HTTPS / Bearer JWT
        Cloudflare Worker (worker-auth)
            │
            ▼ Prepared SQL
        Cloudflare D1 Database (project-zapp-db)
```

The application operates offline-first: local storage guarantees instant UI responsiveness, while the Cloudflare Worker synchronizes timetables and manages squad coordination when online.

## 2. Database Schema

The canonical relational database schema is maintained in [`worker-auth/schema.sql`](../worker-auth/schema.sql). Do not duplicate schema definitions across documentation files.

The schema defines:
1. `users`: Authentication records, password hashes/salts, roles (`USER`, `ADMIN`), and approval states.
2. `courses`: Parsed course records (course code, title, slot, venue, faculty).
3. `user_timetable_slots`: 7-day deconstructed slot schedule matrix for overlap calculations.
4. `groups`: Study Squad identifiers, names, and 8-character unique join codes.
5. `group_members`: Squad membership relationships with roles (`OWNER`, `ADMIN`, `MEMBER`).
6. `rate_limits`: IP/endpoint rate-limiting buckets.

## 3. API Endpoints

All endpoints use JSON payloads and return appropriate HTTP status codes. Authenticated routes require an `Authorization: Bearer <jwt>` header.

### 3.1 Authentication

- `POST /api/login`
  - Body: `{ "username": "...", "password": "...", "isAdmin": false }`
  - Returns: `{ "token": "...", "user": { "id": "...", "username": "...", "role": "USER" } }`

- `POST /api/register`
  - Body: `{ "name": "...", "email": "...", "phone": "...", "username": "...", "password": "..." }`
  - Returns: `{ "message": "Registration submitted for admin approval" }`

### 3.2 Timetable Management

- `POST /api/timetable/upload`
  - Headers: `Authorization: Bearer <token>`
  - Body: `{ "slots": [ { "dayOfWeek": 1, "slotCode": "A1", "courseCode": "BMAT101L", "startTime": "08:00", "endTime": "08:50" } ] }`
  - Stores slots in `user_timetable_slots` and updates the user's schedule.

- `GET /api/timetable/my`
  - Headers: `Authorization: Bearer <token>`
  - Returns the authenticated user's free slot schedule.

- `GET /api/timetable/all` (Admin only)
  - Headers: `Authorization: Bearer <admin-token>`
  - Returns all registered students and their weekly schedules for admin review.

### 3.3 Study Squads

- `GET /api/squad/:code`
  - Headers: `Authorization: Bearer <token>`
  - Returns: `{ "code": "K8M2-9PL4", "name": "Study Squad", "members": [ ... ] }`

- `POST /api/squad/join`
  - Headers: `Authorization: Bearer <token>`
  - Body: `{ "code": "K8M2-9PL4" }`

## 4. Setup and Deployment

### 4.1 Prerequisites

- Node.js (v18+)
- Cloudflare Wrangler CLI:
  ```sh
  npm install -g wrangler
  wrangler login
  ```

### 4.2 Database Provisioning

1. Create the D1 database:
   ```sh
   wrangler d1 create project-zapp-db
   ```
2. Note the generated `database_id` and add it to `wrangler.toml` under `[[d1_databases]]`.

3. Execute the schema:
   ```sh
   # Local testing
   wrangler d1 execute project-zapp-db --local --file=./worker-auth/schema.sql

   # Production deployment
   wrangler d1 execute project-zapp-db --remote --file=./worker-auth/schema.sql
   ```

### 4.3 Worker Deployment

Deploy the worker to Cloudflare:
```sh
cd worker-auth
wrangler deploy
```

### 4.4 Frontend Configuration

Set the worker URL in `lib/core/constants.dart`:
```dart
const String apiBaseUrl = 'https://project-zapp-api.<your-subdomain>.workers.dev';
```

## 5. Verification

Verify the backend deployment:
```sh
# Health check
curl https://project-zapp-api.<your-subdomain>.workers.dev/api/health

# Flutter analyze & test
flutter analyze
flutter test
```
