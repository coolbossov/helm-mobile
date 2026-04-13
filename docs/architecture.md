# HELM Mobile — Architecture

**Last Updated: 2026-04-13**

## What It Is

Native iOS companion app for the HELM field sales route planner web app (`helm-app`). Used by SAPD field sales reps to manage their daily school visit routes from a phone.

## What It Is NOT

- Not a standalone product — requires `helm-app` (Next.js) as the backend/data layer
- Not a web app — native Swift/SwiftUI only, no React Native or cross-platform frameworks
- No iOS-specific Bigin code — CRM sync runs as a 15-min cron on the web app

## Stack

| Layer | Technology |
|---|---|
| Language | Swift 6.0 |
| UI | SwiftUI |
| Min target | iOS 17.0 |
| Auth | Supabase Auth (shared session with web app) |
| Data | Supabase (shared DB with helm-app) |
| Realtime | Supabase Realtime (`route_stops` subscription) |
| Offline | SwiftData cache + pending mutation queue |
| Maps | MapKit |
| Project gen | XcodeGen (`project.yml`) |

## Source Structure

```
Sources/HELM/
├── HELMApp.swift               — App entry point, auth gate, tab view
├── Models/
│   └── Models.swift            — SavedRoute, RouteStop, ContactSummary
├── Services/
│   ├── SupabaseService.swift   — Singleton Supabase client + RouteRepository
│   ├── AuthState.swift         — Observable auth state
│   └── OfflineStore.swift      — SwiftData cache + pending mutation queue
└── Views/
    ├── LoginView.swift
    ├── RouteList/RouteListView.swift
    ├── RouteDetail/
    │   ├── RouteDetailView.swift   — Map + stop list + Realtime subscription
    │   └── RouteMapView.swift      — MapKit map with numbered pins + polyline
    ├── StopDetail/StopDetailView.swift
    └── Settings/SettingsView.swift
```

## Key Features

| Feature | Notes |
|---|---|
| Route list | Pull-to-refresh from Supabase |
| Map view | MapKit with numbered pins + polyline |
| Real-time sync | Supabase Realtime on `route_stops` — live updates across devices |
| Visit logging | Status (pending/visited/skipped), notes, outcome |
| Navigation | Deep links to Apple Maps, Google Maps, or Waze (user-selectable) |
| Offline mode | SwiftData cache; mutations queued and synced on reconnect |

## External Dependencies

| Package | Version | Source |
|---|---|---|
| `supabase-swift` | ≥ 2.5.0 | https://github.com/supabase/supabase-swift |

## Build

```bash
# Generate Xcode project (required before first open)
xcodegen generate

# Open in Xcode
open HELM.xcodeproj
```

Requires: macOS with Xcode 16+, iOS 17+ device/simulator, XcodeGen (`brew install xcodegen`).

## CI

No GitHub Actions CI configured (iOS builds require macOS runner — not set up). Code review via `@review-2-code-commit` before every PR merge.
