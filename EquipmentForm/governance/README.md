# Governance Pack

Drop this `/governance` folder at the root of your repo. It provides:
- PR template enforcing PRD alignment and evidence
- CODEOWNERS for critical areas
- CI pipeline (analyze/tests, golden snapshots, OCR bench)
- Milestone DoR/DoD examples to copy per milestone
- Pre-commit hooks (format/analyze/test)
- Governance agent prompt (pre-/post-flight rituals)

Integrate step-by-step:
1) Copy `.github/` to your repo for CI and CODEOWNERS.
2) Add `PULL_REQUEST_TEMPLATE.md` to `.github/` (or repo root).
3) Install pre-commit script: `chmod +x governance/scripts/pre-commit.sh` and symlink to `.git/hooks/pre-commit`.
4) Create `docs/prd.md`, `/adrs/`, `tasks.md`, and `test/golden`, `test/ocr_bench` folders.
