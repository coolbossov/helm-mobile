# HELM Mobile — iOS Field Sales Route Companion

SwiftUI iOS companion app for the HELM field sales route planner web app.

## Requirements

- macOS with Xcode 16+
- iOS 17+ target device or simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Setup

1. **Generate the Xcode project:**
   ```bash
   xcodegen generate
   ```

2. **Configure environment variables** — Add these to `Supporting/Info.plist` (or use Xcode build settings):
   ```
   SUPABASE_URL       = https://your-project.supabase.co
   SUPABASE_ANON_KEY  = your_anon_key_here
   HELM_API_BASE_URL  = https://your-helm-app.vercel.app
   ```

3. **Open in Xcode:**
   ```bash
   open HELM.xcodeproj
   ```

4. Set your development team in the project settings and run on your device.

## Architecture

```
Sources/HELM/
├── HELMApp.swift           — App entry, auth gate, tab view
├── Models/
│   └── Models.swift        — SavedRoute, RouteStop, ContactSummary
├── Services/
│   ├── SupabaseService.swift  — Singleton client + RouteRepository
│   ├── AuthState.swift        — Observable auth state
│   └── OfflineStore.swift     — SwiftData cache + mutation queue
└── Views/
    ├── LoginView.swift
    ├── RouteList/
    │   └── RouteListView.swift
    ├── RouteDetail/
    │   ├── RouteDetailView.swift   — Map + stop list + Realtime subscription
    │   └── RouteMapView.swift      — MapKit map with numbered pins
    ├── StopDetail/
    │   └── StopDetailView.swift    — Status, notes, outcome, time window, navigation
    └── Settings/
        └── SettingsView.swift
```

## Key Features

| Feature | Implementation |
|---------|---------------|
| Auth | Supabase Auth (shared session with web app) |
| Route list | Fetched from Supabase, pull-to-refresh |
| Route map | MapKit with numbered pins + polyline |
| Real-time sync | Supabase Realtime subscription on `route_stops` |
| Visit logging | Status (pending/visited/skipped), notes, outcome |
| Navigation | Tap to open Apple Maps / Google Maps / Waze |
| Offline | SwiftData cache + pending mutation queue, syncs on reconnect |
| Bigin sync | Via 15-min cron on web app — no iOS-specific Bigin code needed |

## Navigation Deep Links

- **Apple Maps**: `maps://maps.apple.com/?daddr=<lat>,<lng>`
- **Google Maps**: `comgooglemaps://?daddr=<lat>,<lng>&directionsmode=driving`
- **Waze**: `waze://?ll=<lat>,<lng>&navigate=yes`

Set preferred app in Settings tab.
