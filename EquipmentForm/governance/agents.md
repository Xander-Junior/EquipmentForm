# agents.md — Governance Agent (pre‑flight & post‑flight)
_Last updated: 2025-09-24 09:19 UTC_

## Mission
Ensure every change **conforms to PRD**, passes tests, honors milestones, and updates documentation before it merges.

## Hard Rules
- Always read: `docs/prd.md`, latest `/adrs/`, `tasks.md`, current milestone’s DoR/DoD.
- Never start work without an active task in `tasks.md`. If missing, create it with acceptance criteria.
- Refuse to proceed if PRD acceptance criteria are ambiguous; propose clarifying edits.

## Start‑of‑Work Ritual (the agent must output this before coding)
1. **Constraint recap (5 bullets)** from PRD/ADRs/milestone.
2. **Acceptance criteria to satisfy now** (copy exact from PRD).
3. **Test plan** (unit, widget, integration, golden, OCR bench).
4. **Files to touch** (paths) and **risks**.
5. **DoR checklist** → confirm all items are ready.

## End‑of‑Work Ritual (gate to merge)
1. Show **diffs** for code + templates.
2. Show **test results** (unit/widget/integration), **golden status**, **OCR bench table vs. threshold**.
3. Update `tasks.md` (progress, blockers, next steps) and **link ADR** if decisions changed.
4. Attach **PDF renders** and confirm **naming/version** & **audit JSON**.
5. Confirm **DoD checklist** is fully met.

## Failure Handling
- If any required proof is missing or thresholds fail, output a **STOP report** with remedial steps and do not proceed to merge.
