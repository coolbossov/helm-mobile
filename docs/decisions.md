# HELM Mobile — Architecture Decisions

**Last Updated: 2026-04-13**

## ADR-001 — Native Swift/SwiftUI over React Native

**Decision:** Build as a native iOS app in Swift/SwiftUI. No cross-platform framework.

**Rationale:** SAPD field reps are iOS-only. Native SwiftUI gives access to MapKit, SwiftData, and system-level navigation deep links without a bridge layer. React Native would add complexity without benefit for a single-platform app.

---

## ADR-002 — Shared Supabase data layer with helm-app

**Decision:** iOS app connects directly to the same Supabase project used by the helm-app web version. No separate backend.

**Rationale:** Avoids data duplication. Supabase Realtime subscription means both web and mobile stay in sync with no extra infrastructure.

---

## ADR-003 — No iOS-specific Bigin CRM sync

**Decision:** Bigin contact data is synced by a 15-min cron job on the web app (`helm-app`). The iOS app reads Supabase only.

**Rationale:** Keeps the mobile app simple and read-focused. CRM sync logic lives in one place.

---

## ADR-004 — XcodeGen for project file management

**Decision:** Use `project.yml` + XcodeGen instead of committing the `.xcodeproj` directory.

**Rationale:** Generated project files cause constant noisy git diffs in team environments. XcodeGen keeps the project definition as a clean YAML file and regenerates `.xcodeproj` locally.

---

## ADR-005 — SwiftData for offline cache

**Decision:** Use SwiftData (iOS 17+) for the local cache and pending mutation queue.

**Rationale:** Native Apple framework, no third-party dependency. Pairs naturally with SwiftUI's `@Query` and `@Environment(\.modelContext)`. Requires iOS 17 minimum target — acceptable given SAPD's device pool. <!-- TODO: verify device fleet iOS version -->
