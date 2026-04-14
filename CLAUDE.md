# helm-mobile — AI Guardrails

## What this is

iOS companion app for the SAPD Ops field sales map (helm-app). Native Swift app for mobile field use.

## What this is NOT

- Not a web app — native Swift/iOS only, no React Native or cross-platform frameworks
- Not a standalone product — companion to helm-app; shared data layer

## Git workflow (enforced — no exceptions)

- **Never commit directly to `main`** — all code changes go through a branch + PR
- **Auto-branch on first code edit** — the moment a session transitions from research/planning to implementation, create a branch before the first file edit. Use prefix conventions: `feat/`, `fix/`, `chore/`, `docs/`
- **Docs update is part of every PR — not a follow-up** — any change that touches DB schema, API shape, data flows, auth, or architecture must update the relevant `docs/` file(s) in the same commit:
  - New/altered DB columns or tables → `docs/database.md` (schema + migration history)
  - Architecture or flow change → `docs/architecture.md`
  - Design decision or trade-off → `docs/decisions.md` (add ADR, newest first)
  - New integration or external dependency → `docs/integrations.md`
  - New env var → `docs/environment.md`
  - New/changed tests or testable features → `docs/testing.md` (update Quick/Deep/E2E sections)
  - Any shipped change → `CHANGELOG.md` (add entry under today's date)
- **End of session** — run `@review-2-code-commit` before pushing
- Note: no CI auto-merge (Swift — GitHub Actions iOS builds require macOS runner, not configured)

## Architecture notes

- Stack: Swift, SwiftUI, iOS
- Pairs with: helm-app (Next.js web version)
