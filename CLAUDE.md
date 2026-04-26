# helm-mobile — AI Guardrails

## What this is

iOS companion app for the SAPD Ops field sales map (helm-app). Native Swift app for mobile field use.

## What this is NOT

- Not a web app — native Swift/iOS only, no React Native or cross-platform frameworks
- Not a standalone product — companion to helm-app; shared data layer

## Git workflow (direct to production)

This repo overrides the global "branch + PR for all dev repos" rule. Helm mobile (iOS) changes ship straight to `main`. Note: actual production release still goes through Apple App Store review — `main` is the source of truth for the next build, not an instant production deploy.

- **Commit and push directly to `main`** — no feature branches, no PRs.
- **Run local checks before push** — Swift build/test must pass.
- **Docs update is part of every commit — not a follow-up** — any change that touches DB schema, API shape, data flows, auth, or architecture must update the relevant `docs/` file(s) in the same commit:
  - New/altered DB columns or tables → `docs/database.md` (schema + migration history)
  - Architecture or flow change → `docs/architecture.md`
  - Design decision or trade-off → `docs/decisions.md` (add ADR, newest first)
  - New integration or external dependency → `docs/integrations.md`
  - New env var → `docs/environment.md`
  - New/changed tests or testable features → `docs/testing.md` (update Quick/Deep/E2E sections)
  - Any shipped change → `CHANGELOG.md` (add entry under today's date)
- The Kimi pre-commit review hook still runs on every commit. A `BLOCKED` verdict still rejects the commit — fix and retry.
- Branches + PRs are still acceptable for genuinely high-risk changes. Default is straight-to-main.
- Note: no CI auto-merge (Swift — GitHub Actions iOS builds require macOS runner, not configured)

## Architecture notes

- Stack: Swift, SwiftUI, iOS
- Pairs with: helm-app (Next.js web version)
