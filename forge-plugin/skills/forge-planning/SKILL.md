---
name: forge-planning
description: Plan a safe Forge workflow using Claude Code plan mode before any autonomous execution.
---

Forge planning is a conversation, not an execution permission. Use plan mode to structure the work visually. Invoke the `superpowers:brainstorming` skill to run the conversation itself — classify the request (spike/bounded/architectural), ask focused questions one at a time, compare 2-3 approaches with a recommendation, and present the design in sections for approval.

**Handoff from brainstorming to Forge's plan schema:** brainstorming's normal terminal step (write a spec to `docs/superpowers/specs/`, then invoke `writing-plans`) is not used here. The moment the user approves the design inside the brainstorming flow, fold that approved design directly into the Forge plan schema below and write it to `.forge/PLAN.md` — do not create a separate spec file and do not invoke `writing-plans`.

The plan must cover:
- Goal and success criteria
- Context and assumptions
- Alternatives considered and chosen approach
- Allowed scope
- Forbidden / approval-required actions
- Environment constraints
- Task list — each task needs: owner, inputs/allowed paths, expected deliverable, verification command, fallback/pause condition
- Integration and final verification
- Known risks and unverified items

Task owners: `Claude` | `Codex-investigate` | `Codex-setup` | `Codex-review` | `Codex-implement`

Also persist the plan to `.forge/PLAN.md` so it survives session restarts. `.forge/` initialization is the sole allowed write during planning.

Physical-robot actions (motor enable, deployment, policy launch, motion, teleoperation, actuators, networked hardware) are always human-approval-only — never executable. Convert any such request to a human approval checklist task and state clearly that no launch will occur.

When the plan looks complete, call `ExitPlanMode` to request approval — the button approval (e.g. "Yes, auto-accept edits") is the sign-off; no separate confirmation phrase is required. After approval, prompt the user: **"준비됐으면 `/forge-run`을 실행해줘."**
