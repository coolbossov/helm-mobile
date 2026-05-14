# Database

> Last Updated: 2026-05-13

## Status

This file exists as the canonical database path referenced by repo instructions. Document the app's durable data store here as the mobile data model and backend contract settle.

## Current Guidance

- Primary store: See the current app architecture and backend decisions before changing persistence behavior
- Ownership boundary: Keep mobile-local cache behavior separate from server-owned source-of-truth data
- Migration workflow: Record any schema or sync-contract change in `docs/decisions.md` and the changelog
