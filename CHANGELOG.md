# Changelog

All shipped or reviewable changes to this repository, newest first.

## 2026-05-14

- **Summary:** Added the repo infra-doc advisory workflow and updated `AGENTS.md` so shared infrastructure changes route through the canonical infra docs and `/infra-update`.
- **Why:** helm-mobile now participates in the non-blocking shared infra reminder path.
- **Affected areas:** `.github/workflows/infra-doc-advisory.yml`, `AGENTS.md`.
- **Troubleshooting:** If the advisory triggers on workflow or environment changes, check whether the shared infra index needs an update before assuming repo docs are enough.

## 2026-05-13

- **Summary:** Added the managed-repo documentation baseline, changelog workflow, and missing canonical docs paths.
- **Why:** The repo instructions already referenced these docs; the rollout makes the paths real and keeps future Codex sessions consistent.
- **Affected areas:** `AGENTS.md`, `CHANGELOG.md`, `.github/workflows/changelog-enforce.yml`, `docs/database.md`, `docs/environment.md`, `docs/integrations.md`.
- **Troubleshooting:** If future work adds new integration or env-var details, keep the corresponding docs files in sync in the same PR.
